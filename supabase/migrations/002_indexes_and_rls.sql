-- DZ Delivery - Indexes and Row Level Security
-- Migration: Indexes and RLS Policies

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Profiles
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_phone ON public.profiles(phone);

-- Restaurants
CREATE INDEX idx_restaurants_owner ON public.restaurants(owner_id);
CREATE INDEX idx_restaurants_location ON public.restaurants(latitude, longitude);
CREATE INDEX idx_restaurants_cuisine ON public.restaurants(cuisine_type);
CREATE INDEX idx_restaurants_is_open ON public.restaurants(is_open);

-- Menu Items
CREATE INDEX idx_menu_items_restaurant ON public.menu_items(restaurant_id);
CREATE INDEX idx_menu_items_category ON public.menu_items(category_id);
CREATE INDEX idx_menu_items_available ON public.menu_items(is_available);

-- Livreurs
CREATE INDEX idx_livreurs_user ON public.livreurs(user_id);
CREATE INDEX idx_livreurs_location ON public.livreurs(current_latitude, current_longitude);
CREATE INDEX idx_livreurs_available ON public.livreurs(is_available, is_online);

-- Orders
CREATE INDEX idx_orders_customer ON public.orders(customer_id);
CREATE INDEX idx_orders_restaurant ON public.orders(restaurant_id);
CREATE INDEX idx_orders_livreur ON public.orders(livreur_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_created ON public.orders(created_at DESC);

-- Livreur Locations
CREATE INDEX idx_livreur_locations_livreur ON public.livreur_locations(livreur_id);
CREATE INDEX idx_livreur_locations_order ON public.livreur_locations(order_id);
CREATE INDEX idx_livreur_locations_time ON public.livreur_locations(recorded_at DESC);

-- Notifications
CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = false;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livreurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livreur_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PROFILES POLICIES
-- ============================================
CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

-- ============================================
-- RESTAURANTS POLICIES
-- ============================================
CREATE POLICY "Restaurants are viewable by everyone"
    ON public.restaurants FOR SELECT
    USING (true);

CREATE POLICY "Restaurant owners can update their restaurant"
    ON public.restaurants FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Restaurant owners can insert their restaurant"
    ON public.restaurants FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- ============================================
-- MENU POLICIES
-- ============================================
CREATE POLICY "Menu categories are viewable by everyone"
    ON public.menu_categories FOR SELECT
    USING (true);

CREATE POLICY "Menu items are viewable by everyone"
    ON public.menu_items FOR SELECT
    USING (true);

CREATE POLICY "Restaurant owners can manage menu categories"
    ON public.menu_categories FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurants
            WHERE id = menu_categories.restaurant_id
            AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Restaurant owners can manage menu items"
    ON public.menu_items FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurants
            WHERE id = menu_items.restaurant_id
            AND owner_id = auth.uid()
        )
    );

-- ============================================
-- LIVREURS POLICIES
-- ============================================
CREATE POLICY "Livreurs are viewable by everyone"
    ON public.livreurs FOR SELECT
    USING (true);

CREATE POLICY "Livreurs can update their own data"
    ON public.livreurs FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================
-- ORDERS POLICIES
-- ============================================
CREATE POLICY "Customers can view their orders"
    ON public.orders FOR SELECT
    USING (auth.uid() = customer_id);

CREATE POLICY "Restaurants can view their orders"
    ON public.orders FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurants
            WHERE id = orders.restaurant_id
            AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Livreurs can view assigned orders"
    ON public.orders FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.livreurs
            WHERE id = orders.livreur_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Customers can create orders"
    ON public.orders FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Involved parties can update orders"
    ON public.orders FOR UPDATE
    USING (
        auth.uid() = customer_id
        OR EXISTS (
            SELECT 1 FROM public.restaurants
            WHERE id = orders.restaurant_id
            AND owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.livreurs
            WHERE id = orders.livreur_id
            AND user_id = auth.uid()
        )
    );

-- ============================================
-- ORDER ITEMS POLICIES
-- ============================================
CREATE POLICY "Order items follow order access"
    ON public.order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE id = order_items.order_id
            AND (
                customer_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.restaurants
                    WHERE id = orders.restaurant_id
                    AND owner_id = auth.uid()
                )
            )
        )
    );

-- ============================================
-- REVIEWS POLICIES
-- ============================================
CREATE POLICY "Reviews are viewable by everyone"
    ON public.reviews FOR SELECT
    USING (true);

CREATE POLICY "Customers can create reviews for their orders"
    ON public.reviews FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

-- ============================================
-- LIVREUR LOCATIONS POLICIES
-- ============================================
CREATE POLICY "Livreur locations viewable by involved parties"
    ON public.livreur_locations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE id = livreur_locations.order_id
            AND (
                customer_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.restaurants
                    WHERE id = orders.restaurant_id
                    AND owner_id = auth.uid()
                )
            )
        )
        OR EXISTS (
            SELECT 1 FROM public.livreurs
            WHERE id = livreur_locations.livreur_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Livreurs can insert their locations"
    ON public.livreur_locations FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.livreurs
            WHERE id = livreur_locations.livreur_id
            AND user_id = auth.uid()
        )
    );

-- ============================================
-- NOTIFICATIONS POLICIES
-- ============================================
CREATE POLICY "Users can view their notifications"
    ON public.notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their notifications"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================
-- FCM TOKENS POLICIES
-- ============================================
CREATE POLICY "Users can manage their FCM tokens"
    ON public.fcm_tokens FOR ALL
    USING (auth.uid() = user_id);
