-- 20260711000000_ambarket_admin_withdrawals.sql

-- Allow admins to review seller withdrawal requests.
DROP POLICY IF EXISTS "Admins can view all withdrawals" ON public.seller_withdrawals;
CREATE POLICY "Admins can view all withdrawals"
  ON public.seller_withdrawals
  FOR SELECT
  USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can update withdrawals" ON public.seller_withdrawals;
CREATE POLICY "Admins can update withdrawals"
  ON public.seller_withdrawals
  FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Keep withdrawal submission aligned with the app's source of truth:
-- completed orders minus pending/approved withdrawals. Older trigger versions
-- used seller_wallets.available_balance directly, which could be stale and make
-- the app report a successful request even though no withdrawal row was stored.
CREATE OR REPLACE FUNCTION public.process_dummy_withdrawal()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_revenue numeric := 0;
  v_pending numeric := 0;
  v_withdrawn numeric := 0;
  v_available numeric := 0;
BEGIN
  SELECT COALESCE(SUM(total_price), 0)
  INTO v_total_revenue
  FROM public.orders
  WHERE seller_id = NEW.seller_id
    AND status = 'completed';

  SELECT COALESCE(SUM(amount), 0)
  INTO v_pending
  FROM public.seller_withdrawals
  WHERE seller_id = NEW.seller_id
    AND status = 'pending';

  SELECT COALESCE(SUM(amount), 0)
  INTO v_withdrawn
  FROM public.seller_withdrawals
  WHERE seller_id = NEW.seller_id
    AND status = 'approved_dummy';

  v_available := GREATEST(0, v_total_revenue - v_pending - v_withdrawn);

  IF v_available < NEW.amount THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;

  INSERT INTO public.seller_wallets (
    seller_id,
    available_balance,
    pending_balance,
    total_earning,
    updated_at
  )
  VALUES (
    NEW.seller_id,
    GREATEST(0, v_available - NEW.amount),
    v_pending + NEW.amount,
    v_total_revenue,
    now()
  )
  ON CONFLICT (seller_id) DO UPDATE SET
    available_balance = EXCLUDED.available_balance,
    pending_balance = EXCLUDED.pending_balance,
    total_earning = EXCLUDED.total_earning,
    updated_at = now();

  RETURN NEW;
END;
$$;

-- Admin read RPCs keep the mobile client simple while avoiding silent empty
-- lists when direct table reads are restricted by RLS policy drift.
CREATE OR REPLACE FUNCTION public.fetch_admin_seller_withdrawals(
  p_limit integer DEFAULT 20,
  p_offset integer DEFAULT 0
)
RETURNS SETOF public.seller_withdrawals
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can read seller withdrawals';
  END IF;

  RETURN QUERY
  SELECT sw.*
  FROM public.seller_withdrawals sw
  ORDER BY sw.created_at DESC
  LIMIT GREATEST(p_limit, 0)
  OFFSET GREATEST(p_offset, 0);
END;
$$;

CREATE OR REPLACE FUNCTION public.count_admin_pending_withdrawals()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can count seller withdrawals';
  END IF;

  SELECT COUNT(*)::integer
  INTO v_count
  FROM public.seller_withdrawals
  WHERE status = 'pending';

  RETURN COALESCE(v_count, 0);
END;
$$;

-- Extend notification RPC authorization for withdrawal workflows:
-- sellers may notify admins about a withdrawal request, and admins may notify
-- the seller when the request is approved/rejected.
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
  -- Always allow sending a notification to oneself.
  IF p_user_id = auth.uid() THEN
    v_is_authorized := true;
  END IF;

  -- Validate Order-related notifications.
  IF NOT v_is_authorized AND p_related_type = 'order' AND p_related_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.orders
      WHERE id = p_related_id
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
      AND (buyer_id = p_user_id OR seller_id = p_user_id)
    ) INTO v_is_authorized;
  END IF;

  -- Validate Offer-related notifications where related_id is provided.
  IF NOT v_is_authorized AND p_related_type = 'offer' AND p_related_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.offers
      WHERE id = p_related_id
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
      AND (buyer_id = p_user_id OR seller_id = p_user_id)
    ) INTO v_is_authorized;
  END IF;

  -- Validate Offer-related notifications where related_id is NULL.
  IF NOT v_is_authorized AND p_related_type = 'offer' AND p_type = 'offer_received' AND p_related_id IS NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.offers
      WHERE buyer_id = auth.uid() AND seller_id = p_user_id
    ) INTO v_is_authorized;
  END IF;

  -- Validate Withdrawal notifications.
  IF NOT v_is_authorized AND p_related_type = 'withdrawal' AND p_related_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1
      FROM public.seller_withdrawals sw
      JOIN public.profiles receiver ON receiver.id = p_user_id
      WHERE sw.id = p_related_id
      AND sw.seller_id = auth.uid()
      AND receiver.role = 'admin'
    ) INTO v_is_authorized;
  END IF;

  IF NOT v_is_authorized AND p_related_type = 'withdrawal' AND p_related_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1
      FROM public.seller_withdrawals sw
      WHERE sw.id = p_related_id
      AND sw.seller_id = p_user_id
      AND public.is_admin()
    ) INTO v_is_authorized;
  END IF;

  IF NOT v_is_authorized THEN
    RAISE EXCEPTION 'Unauthorized to send notification to this user';
  END IF;

  INSERT INTO public.notifications (user_id, type, title, body, related_type, related_id)
  VALUES (p_user_id, p_type, p_title, p_body, p_related_type, p_related_id);
END;
$$;
