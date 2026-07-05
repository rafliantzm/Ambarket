-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS on_order_created ON public.orders;
DROP FUNCTION IF EXISTS public.update_product_status_on_order();

-- Alter products status check constraint to include 'reserved'
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_status_check;
ALTER TABLE public.products ADD CONSTRAINT products_status_check CHECK (status IN ('active', 'reserved', 'sold', 'archived'));

-- Make sure an offer can only be checked out once
ALTER TABLE public.orders ADD CONSTRAINT unique_offer_order UNIQUE (offer_id);

-- New Trigger 1: When an order is created, product becomes 'reserved'
CREATE OR REPLACE FUNCTION set_product_reserved_on_order()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.products
    SET status = 'reserved', updated_at = now()
    WHERE id = NEW.product_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_order_created
    AFTER INSERT ON public.orders
    FOR EACH ROW EXECUTE PROCEDURE set_product_reserved_on_order();

-- New Trigger 2: Handle order status updates (completed -> sold, cancelled -> active if reserved)
CREATE OR REPLACE FUNCTION handle_order_status_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE public.products
        SET status = 'sold', updated_at = now()
        WHERE id = NEW.product_id;
    ELSIF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        -- Only restore to active if it was reserved by this order. 
        -- If it was already sold (somehow), we might not want to revert it automatically, 
        -- but typically cancelled orders means it should go back to active.
        -- We just update it if it's currently reserved.
        UPDATE public.products
        SET status = 'active', updated_at = now()
        WHERE id = NEW.product_id AND status = 'reserved';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_order_updated
    AFTER UPDATE OF status ON public.orders
    FOR EACH ROW EXECUTE PROCEDURE handle_order_status_update();
