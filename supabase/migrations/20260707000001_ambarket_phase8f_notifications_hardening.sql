-- 20260707_04_notification_hardening.sql

-- 1. Create trigger function to prevent tampering with notification content
CREATE OR REPLACE FUNCTION public.prevent_notification_tampering()
RETURNS TRIGGER AS $$
BEGIN
    -- Allow updates ONLY to is_read. If any other column is modified, raise an exception.
    -- (id, user_id, type, title, body, related_type, related_id, created_at)
    IF NEW.id IS DISTINCT FROM OLD.id OR
       NEW.user_id IS DISTINCT FROM OLD.user_id OR
       NEW.type IS DISTINCT FROM OLD.type OR
       NEW.title IS DISTINCT FROM OLD.title OR
       NEW.body IS DISTINCT FROM OLD.body OR
       NEW.related_type IS DISTINCT FROM OLD.related_type OR
       NEW.related_id IS DISTINCT FROM OLD.related_id OR
       NEW.created_at IS DISTINCT FROM OLD.created_at THEN
        RAISE EXCEPTION 'Unauthorized: Only is_read can be updated';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trigger_prevent_notification_tampering ON public.notifications;

-- Create trigger
CREATE TRIGGER trigger_prevent_notification_tampering
BEFORE UPDATE ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.prevent_notification_tampering();

-- 2. Secure RPC for creating dummy notifications
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
DECLARE
  v_is_authorized boolean := false;
BEGIN
  -- Always allow sending a notification to oneself
  IF p_user_id = auth.uid() THEN
    v_is_authorized := true;
  END IF;

  -- Validation logic if sender is not the receiver
  -- A. Validate Order-related notifications
  IF NOT v_is_authorized AND p_related_type = 'order' AND p_related_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.orders
      WHERE id = p_related_id 
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
      AND (buyer_id = p_user_id OR seller_id = p_user_id)
    ) INTO v_is_authorized;
  END IF;

  -- B. Validate Offer-related notifications (where related_id is provided)
  IF NOT v_is_authorized AND p_related_type = 'offer' AND p_related_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.offers
      WHERE id = p_related_id 
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
      AND (buyer_id = p_user_id OR seller_id = p_user_id)
    ) INTO v_is_authorized;
  END IF;

  -- C. Validate Offer-related notifications (where related_id is NULL, e.g. offer_received)
  -- Heuristic: Check if auth.uid() recently made an offer to p_user_id's product.
  IF NOT v_is_authorized AND p_related_type = 'offer' AND p_type = 'offer_received' AND p_related_id IS NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.offers
      WHERE buyer_id = auth.uid() AND seller_id = p_user_id
    ) INTO v_is_authorized;
  END IF;

  -- Reject if not authorized
  IF NOT v_is_authorized THEN
    RAISE EXCEPTION 'Unauthorized to send notification to this user';
  END IF;
  
  INSERT INTO public.notifications (user_id, type, title, body, related_type, related_id)
  VALUES (p_user_id, p_type, p_title, p_body, p_related_type, p_related_id);
END;
$$;
