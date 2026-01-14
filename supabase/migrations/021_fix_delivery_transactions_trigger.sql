-- ============================================
-- FIX: Trigger create_delivery_transactions
-- ============================================

DROP TRIGGER IF EXISTS create_delivery_transactions_trigger ON public.orders;
DROP FUNCTION IF EXISTS create_delivery_transactions();

CREATE OR REPLACE FUNCTION create_delivery_transactions()
RETURNS TRIGGER AS $$
BEGIN
    -- Seulement quand le statut passe à 'delivered'
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Transaction pour le livreur
        INSERT INTO public.transactions (order_id, type, amount, recipient_id, status)
        SELECT NEW.id, 'livreur_earning', NEW.livreur_commission, l.user_id, 'completed'
        FROM public.livreurs l WHERE l.id = NEW.livreur_id;
        
        -- Transaction pour le restaurant
        INSERT INTO public.transactions (order_id, type, amount, recipient_id, status)
        SELECT NEW.id, 'restaurant_earning', NEW.subtotal, r.owner_id, 'completed'
        FROM public.restaurants r WHERE r.id = NEW.restaurant_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_delivery_transactions_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION create_delivery_transactions();

-- Vérifier
SELECT '✅ Trigger create_delivery_transactions corrigé' as message;
