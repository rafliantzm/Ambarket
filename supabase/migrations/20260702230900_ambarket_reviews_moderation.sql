-- Add moderation fields to reviews table
ALTER TABLE public.reviews 
ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS moderation_note TEXT,
ADD COLUMN IF NOT EXISTS moderated_at TIMESTAMPTZ;

-- Allow admin to read and update
DROP POLICY IF EXISTS "Admins can update reviews" ON public.reviews;
CREATE POLICY "Admins can update reviews" 
ON public.reviews FOR UPDATE 
USING (public.is_admin());
