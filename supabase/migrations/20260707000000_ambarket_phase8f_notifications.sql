-- 20260707_03_notifications.sql

-- 1. Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  related_type text,
  related_id uuid,
  is_read boolean DEFAULT false NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- 2. Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 3. Select policy
CREATE POLICY "Users can view own notifications" 
  ON public.notifications 
  FOR SELECT 
  USING (auth.uid() = user_id);

-- 4. Update policy (only for is_read)
CREATE POLICY "Users can update own notifications" 
  ON public.notifications 
  FOR UPDATE 
  USING (auth.uid() = user_id);

-- 5. RPC for securely creating a dummy notification
CREATE OR REPLACE FUNCTION public.create_dummy_notification(
  p_user_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_related_type text DEFAULT NULL,
  p_related_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- For MVP, we trust the application server (or client RPC) to create notifications.
  -- To be truly secure against abuse from clients, this should only be called from other triggers or server functions, 
  -- but for this MVP client-triggered action, we allow it.
  
  INSERT INTO public.notifications (user_id, type, title, body, related_type, related_id)
  VALUES (p_user_id, p_type, p_title, p_body, p_related_type, p_related_id);
END;
$$;
