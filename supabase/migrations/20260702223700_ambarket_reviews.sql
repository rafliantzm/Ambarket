-- Create reviews table
CREATE TABLE public.reviews (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id uuid REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    product_id uuid REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    reviewer_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    reviewed_user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT unique_order_reviewer UNIQUE (order_id, reviewer_id)
);

-- Trigger for updated_at
CREATE TRIGGER on_review_updated
    BEFORE UPDATE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Enable RLS
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read reviews
CREATE POLICY "Public read access for reviews"
ON public.reviews FOR SELECT
USING (true);

-- Policy: Buyer can insert review for completed order
CREATE POLICY "Buyers can insert review for completed order"
ON public.reviews FOR INSERT
WITH CHECK (
    auth.uid() = reviewer_id AND
    EXISTS (
        SELECT 1 FROM public.orders
        WHERE orders.id = order_id
        AND orders.buyer_id = auth.uid()
        AND orders.status = 'completed'
        AND orders.product_id = product_id
        AND orders.seller_id = reviewed_user_id
    )
);

-- Policy: Reviewer can update their own review
CREATE POLICY "Users can update their own review"
ON public.reviews FOR UPDATE
USING (auth.uid() = reviewer_id);
