-- ============================================
-- FIX: Fonction get_restaurant_stats
-- ============================================

DROP FUNCTION IF EXISTS get_restaurant_stats(UUID);

CREATE OR REPLACE FUNCTION get_restaurant_stats(restaurant_uuid UUID)
RETURNS TABLE (
    total_orders BIGINT, 
    total_revenue DECIMAL, 
    orders_today BIGINT, 
    revenue_today DECIMAL, 
    avg_order_value DECIMAL, 
    pending_orders BIGINT,
    avg_prep_time INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT, 
        COALESCE(SUM(o.total), 0),
        COUNT(*) FILTER (WHERE DATE(o.created_at) = CURRENT_DATE)::BIGINT,
        COALESCE(SUM(o.total) FILTER (WHERE DATE(o.created_at) = CURRENT_DATE), 0),
        COALESCE(AVG(o.total), 0),
        COUNT(*) FILTER (WHERE o.status IN ('pending', 'confirmed', 'preparing'))::BIGINT,
        (SELECT COALESCE(r.avg_prep_time, 30) FROM public.restaurants r WHERE r.id = restaurant_uuid)::INTEGER
    FROM public.orders o
    WHERE o.restaurant_id = restaurant_uuid AND o.status != 'cancelled';
END;
$$ LANGUAGE plpgsql;

-- Tester la fonction
SELECT * FROM get_restaurant_stats(
    (SELECT id FROM restaurants WHERE name = 'Restaurant Test')
);
