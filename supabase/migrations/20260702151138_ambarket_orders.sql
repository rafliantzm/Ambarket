-- Add phone and address to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS address TEXT;

-- Create orders table
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    offer_id UUID REFERENCES public.offers(id) ON DELETE SET NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    buyer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    seller_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    total_price DECIMAL(12, 2) NOT NULL,
    shipping_address TEXT NOT NULL,
    shipping_phone TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending_payment' CHECK (status IN ('pending_payment', 'paid', 'shipped', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Trigger for updated_at
CREATE TRIGGER handle_orders_updated_at 
    BEFORE UPDATE ON public.orders 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Trigger to update product status to sold when order is created
CREATE OR REPLACE FUNCTION update_product_status_on_order()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.products
    SET status = 'sold', updated_at = now()
    WHERE id = NEW.product_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_order_created
    AFTER INSERT ON public.orders
    FOR EACH ROW EXECUTE PROCEDURE update_product_status_on_order();

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- RLS Policies for orders
-- Users can view their own orders (as buyer or seller)
CREATE POLICY "Users can view their own orders" 
ON public.orders FOR SELECT 
USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- Buyer can insert an order for themselves
CREATE POLICY "Buyers can insert orders" 
ON public.orders FOR INSERT 
WITH CHECK (auth.uid() = buyer_id);

-- Users can update their own orders (buyer/seller)
CREATE POLICY "Users can update their own orders" 
ON public.orders FOR UPDATE 
USING (auth.uid() = buyer_id OR auth.uid() = seller_id);
