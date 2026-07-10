-- Fix ambiguous columns in reviews RLS policy
DROP POLICY IF EXISTS "Buyers can insert review for completed order" ON public.reviews;

CREATE POLICY "Buyers can insert review for completed order"
ON public.reviews FOR INSERT
WITH CHECK (
    auth.uid() = reviewer_id AND
    EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_id
        AND o.buyer_id = auth.uid()
        AND o.status = 'completed'
        AND o.product_id = product_id
        AND o.seller_id = reviewed_user_id
    )
);
