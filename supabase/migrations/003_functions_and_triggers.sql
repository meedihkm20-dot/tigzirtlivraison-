-- DZ Delivery - Functions and Triggers
-- Migration: Database Functions and Triggers

-- ============================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_restaurants_updated_at
    BEFORE UPDATE ON public.restaurants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_menu_items_updated_at
    BEFORE UPDATE ON public.menu_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_livreurs_updated_at
    BEFORE UPDATE ON public.livreurs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- AUTO-CREATE PROFILE ON SIGNUP
-- ============================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'customer')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================
-- GENERATE ORDER NUMBER
-- ============================================
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
    today_count INTEGER;
BEGIN
    SELECT COUNT(*) + 1 INTO today_count
    FROM public.orders
    WHERE DATE(created_at) = CURRENT_DATE;
    
    NEW.order_number = 'DZ' || TO_CHAR(CURRENT_DATE, 'YYMMDD') || LPAD(today_count::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_order_number_trigger
    BEFORE INSERT ON public.orders
    FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- ============================================
-- UPDATE RESTAURANT RATING
-- ============================================
CREATE OR REPLACE FUNCTION update_restaurant_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.restaurants
    SET 
        rating = (
            SELECT COALESCE(AVG(restaurant_rating), 0)
            FROM public.reviews
            WHERE restaurant_id = NEW.restaurant_id
            AND restaurant_rating IS NOT NULL
        ),
        total_reviews = (
            SELECT COUNT(*)
            FROM public.reviews
            WHERE restaurant_id = NEW.restaurant_id
            AND restaurant_rating IS NOT NULL
        )
    WHERE id = NEW.restaurant_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_restaurant_rating_trigger
    AFTER INSERT OR UPDATE ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION update_restaurant_rating();

-- ============================================
-- UPDATE LIVREUR STATS
-- ============================================
CREATE OR REPLACE FUNCTION update_livreur_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update on delivery completion
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        UPDATE public.livreurs
        SET 
            total_deliveries = total_deliveries + 1,
            total_earnings = total_earnings + NEW.delivery_fee
        WHERE id = NEW.livreur_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_livreur_stats_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION update_livreur_stats();

-- ============================================
-- FIND NEARBY RESTAURANTS
-- ============================================
CREATE OR REPLACE FUNCTION get_nearby_restaurants(
    user_lat DECIMAL,
    user_lng DECIMAL,
    radius_km DECIMAL DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    description TEXT,
    logo_url TEXT,
    cuisine_type VARCHAR,
    rating DECIMAL,
    delivery_fee DECIMAL,
    avg_prep_time INTEGER,
    distance_km DECIMAL,
    is_open BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        r.name,
        r.description,
        r.logo_url,
        r.cuisine_type,
        r.rating,
        r.delivery_fee,
        r.avg_prep_time,
        (
            6371 * acos(
                cos(radians(user_lat)) * cos(radians(r.latitude)) *
                cos(radians(r.longitude) - radians(user_lng)) +
                sin(radians(user_lat)) * sin(radians(r.latitude))
            )
        )::DECIMAL AS distance_km,
        r.is_open
    FROM public.restaurants r
    WHERE r.is_verified = true
    AND (
        6371 * acos(
            cos(radians(user_lat)) * cos(radians(r.latitude)) *
            cos(radians(r.longitude) - radians(user_lng)) +
            sin(radians(user_lat)) * sin(radians(r.latitude))
        )
    ) <= radius_km
    ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FIND AVAILABLE LIVREURS
-- ============================================
CREATE OR REPLACE FUNCTION get_available_livreurs(
    restaurant_lat DECIMAL,
    restaurant_lng DECIMAL,
    radius_km DECIMAL DEFAULT 5
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    full_name VARCHAR,
    phone VARCHAR,
    vehicle_type vehicle_type,
    rating DECIMAL,
    distance_km DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id,
        l.user_id,
        p.full_name,
        p.phone,
        l.vehicle_type,
        l.rating,
        (
            6371 * acos(
                cos(radians(restaurant_lat)) * cos(radians(l.current_latitude)) *
                cos(radians(l.current_longitude) - radians(restaurant_lng)) +
                sin(radians(restaurant_lat)) * sin(radians(l.current_latitude))
            )
        )::DECIMAL AS distance_km
    FROM public.livreurs l
    JOIN public.profiles p ON p.id = l.user_id
    WHERE l.is_available = true
    AND l.is_online = true
    AND l.is_verified = true
    AND l.current_latitude IS NOT NULL
    AND (
        6371 * acos(
            cos(radians(restaurant_lat)) * cos(radians(l.current_latitude)) *
            cos(radians(l.current_longitude) - radians(restaurant_lng)) +
            sin(radians(restaurant_lat)) * sin(radians(l.current_latitude))
        )
    ) <= radius_km
    ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- GET ORDER STATISTICS
-- ============================================
CREATE OR REPLACE FUNCTION get_restaurant_stats(restaurant_uuid UUID)
RETURNS TABLE (
    total_orders BIGINT,
    total_revenue DECIMAL,
    orders_today BIGINT,
    revenue_today DECIMAL,
    avg_order_value DECIMAL,
    pending_orders BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT AS total_orders,
        COALESCE(SUM(total), 0) AS total_revenue,
        COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE)::BIGINT AS orders_today,
        COALESCE(SUM(total) FILTER (WHERE DATE(created_at) = CURRENT_DATE), 0) AS revenue_today,
        COALESCE(AVG(total), 0) AS avg_order_value,
        COUNT(*) FILTER (WHERE status IN ('pending', 'confirmed', 'preparing'))::BIGINT AS pending_orders
    FROM public.orders
    WHERE orders.restaurant_id = restaurant_uuid
    AND status != 'cancelled';
END;
$$ LANGUAGE plpgsql;
