-- Add new fields to public.orders
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS receiver_name TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS receiver_phone TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS shipping_method TEXT DEFAULT 'cod';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS shipping_cost DECIMAL(12, 2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cod';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'unpaid';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_due_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS invoice_number TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS voucher_code TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(12, 2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS service_fee DECIMAL(12, 2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS subtotal DECIMAL(12, 2) DEFAULT 0;

-- Backfill subtotal with total_price and copy receiver info from shipping if null
UPDATE public.orders SET 
    subtotal = total_price,
    receiver_name = 'Receiver', -- Default since we didn't have it before
    receiver_phone = shipping_phone
WHERE subtotal = 0;

-- Drop existing status check constraint dynamically and add new one
DO $$ 
DECLARE constraint_name text; 
BEGIN 
    SELECT conname INTO constraint_name 
    FROM pg_constraint 
    WHERE conrelid = 'public.orders'::regclass 
    AND contype = 'c' 
    AND conname LIKE '%status%'; 

    IF constraint_name IS NOT NULL THEN 
        EXECUTE 'ALTER TABLE public.orders DROP CONSTRAINT ' || constraint_name; 
    END IF; 
END $$;

ALTER TABLE public.orders ADD CONSTRAINT orders_status_check 
CHECK (status IN ('pending_payment', 'paid', 'packed', 'shipped', 'completed', 'cancelled'));

-- Update product status trigger
CREATE OR REPLACE FUNCTION update_product_status_on_order()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.products
    SET status = 'reserved', updated_at = now()
    WHERE id = NEW.product_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create cart_items table
CREATE TABLE public.cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    quantity INTEGER DEFAULT 1 CHECK (quantity = 1),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, product_id)
);

-- Trigger for cart_items updated_at
CREATE TRIGGER handle_cart_items_updated_at 
    BEFORE UPDATE ON public.cart_items 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- RLS for cart_items
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own cart" 
ON public.cart_items FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert to their own cart" 
ON public.cart_items FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cart" 
ON public.cart_items FOR DELETE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own cart" 
ON public.cart_items FOR UPDATE 
USING (auth.uid() = user_id);
