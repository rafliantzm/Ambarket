-- Escrow, dispute, and refund workflow for Ambarket orders.
-- This migration is intentionally additive and idempotent so existing orders,
-- wallets, and withdrawal flows keep working.

ALTER TABLE public.seller_wallets
  ADD COLUMN IF NOT EXISTS disputed_balance numeric DEFAULT 0 NOT NULL;

CREATE TABLE IF NOT EXISTS public.order_refund_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  buyer_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  seller_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  reason text NOT NULL,
  description text NOT NULL,
  evidence_urls text[] DEFAULT '{}'::text[] NOT NULL,
  requested_amount numeric NOT NULL CHECK (requested_amount > 0),
  approved_amount numeric DEFAULT 0 NOT NULL CHECK (approved_amount >= 0),
  status text DEFAULT 'submitted' NOT NULL CHECK (
    status IN (
      'submitted',
      'seller_responded',
      'under_review',
      'approved',
      'partially_approved',
      'rejected',
      'cancelled'
    )
  ),
  seller_response text,
  admin_note text,
  resolved_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  resolved_at timestamptz,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_order_refund_requests_order_id
  ON public.order_refund_requests(order_id);
CREATE INDEX IF NOT EXISTS idx_order_refund_requests_buyer_id
  ON public.order_refund_requests(buyer_id);
CREATE INDEX IF NOT EXISTS idx_order_refund_requests_seller_id
  ON public.order_refund_requests(seller_id);
CREATE INDEX IF NOT EXISTS idx_order_refund_requests_status
  ON public.order_refund_requests(status);
CREATE INDEX IF NOT EXISTS idx_order_refund_requests_created_at
  ON public.order_refund_requests(created_at DESC);

DROP TRIGGER IF EXISTS handle_order_refund_requests_updated_at
  ON public.order_refund_requests;
CREATE TRIGGER handle_order_refund_requests_updated_at
  BEFORE UPDATE ON public.order_refund_requests
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  refund_id uuid REFERENCES public.order_refund_requests(id) ON DELETE SET NULL,
  withdrawal_id uuid REFERENCES public.seller_withdrawals(id) ON DELETE SET NULL,
  type text NOT NULL,
  amount numeric NOT NULL,
  balance_bucket text NOT NULL CHECK (
    balance_bucket IN ('available', 'pending', 'disputed', 'withdrawal', 'refund')
  ),
  status text DEFAULT 'posted' NOT NULL,
  description text,
  metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_id
  ON public.wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_order_id
  ON public.wallet_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_refund_id
  ON public.wallet_transactions(refund_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at
  ON public.wallet_transactions(created_at DESC);

ALTER TABLE public.order_refund_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Order participants can view refunds"
  ON public.order_refund_requests;
CREATE POLICY "Order participants can view refunds"
  ON public.order_refund_requests
  FOR SELECT
  USING (auth.uid() = buyer_id OR auth.uid() = seller_id OR public.is_admin());

DROP POLICY IF EXISTS "Buyer can create own refund request"
  ON public.order_refund_requests;
CREATE POLICY "Buyer can create own refund request"
  ON public.order_refund_requests
  FOR INSERT
  WITH CHECK (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Admins can update refund requests"
  ON public.order_refund_requests;
CREATE POLICY "Admins can update refund requests"
  ON public.order_refund_requests
  FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Users can view own wallet transactions"
  ON public.wallet_transactions;
CREATE POLICY "Users can view own wallet transactions"
  ON public.wallet_transactions
  FOR SELECT
  USING (auth.uid() = user_id OR public.is_admin());

DO $$
DECLARE
  constraint_name text;
BEGIN
  SELECT conname INTO constraint_name
  FROM pg_constraint
  WHERE conrelid = 'public.orders'::regclass
    AND contype = 'c'
    AND conname LIKE '%status%'
  LIMIT 1;

  IF constraint_name IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.orders DROP CONSTRAINT ' || quote_ident(constraint_name);
  END IF;

  ALTER TABLE public.orders ADD CONSTRAINT orders_status_check
  CHECK (
    status IN (
      'pending_payment',
      'paid',
      'packed',
      'shipped',
      'delivered',
      'completed',
      'disputed',
      'refunded',
      'partially_refunded',
      'cancelled'
    )
  );
END $$;

CREATE OR REPLACE FUNCTION public.ensure_seller_wallet_exists(p_seller_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.seller_wallets (
    seller_id,
    available_balance,
    pending_balance,
    disputed_balance,
    total_earning,
    updated_at
  )
  VALUES (p_seller_id, 0, 0, 0, 0, now())
  ON CONFLICT (seller_id) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_seller_wallet(p_seller_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_completed_revenue numeric := 0;
  v_pending_orders numeric := 0;
  v_disputed_orders numeric := 0;
  v_pending_withdrawals numeric := 0;
  v_approved_withdrawals numeric := 0;
BEGIN
  PERFORM public.ensure_seller_wallet_exists(p_seller_id);

  SELECT COALESCE(SUM(
    CASE
      WHEN o.status = 'partially_refunded' THEN GREATEST(
        0,
        o.total_price - COALESCE((
          SELECT r.approved_amount
          FROM public.order_refund_requests r
          WHERE r.order_id = o.id
            AND r.status = 'partially_approved'
          ORDER BY r.resolved_at DESC NULLS LAST, r.updated_at DESC
          LIMIT 1
        ), 0)
      )
      ELSE o.total_price
    END
  ), 0)
  INTO v_completed_revenue
  FROM public.orders o
  WHERE o.seller_id = p_seller_id
    AND o.status IN ('completed', 'partially_refunded');

  SELECT COALESCE(SUM(total_price), 0)
  INTO v_pending_orders
  FROM public.orders
  WHERE seller_id = p_seller_id
    AND status IN ('paid', 'packed', 'shipped', 'delivered');

  SELECT COALESCE(SUM(total_price), 0)
  INTO v_disputed_orders
  FROM public.orders
  WHERE seller_id = p_seller_id
    AND status = 'disputed';

  SELECT COALESCE(SUM(amount), 0)
  INTO v_pending_withdrawals
  FROM public.seller_withdrawals
  WHERE seller_id = p_seller_id
    AND status = 'pending';

  SELECT COALESCE(SUM(amount), 0)
  INTO v_approved_withdrawals
  FROM public.seller_withdrawals
  WHERE seller_id = p_seller_id
    AND status = 'approved_dummy';

  UPDATE public.seller_wallets
  SET total_earning = v_completed_revenue,
      pending_balance = v_pending_orders,
      disputed_balance = v_disputed_orders,
      available_balance = GREATEST(
        0,
        v_completed_revenue - v_pending_withdrawals - v_approved_withdrawals
      ),
      updated_at = now()
  WHERE seller_id = p_seller_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.process_dummy_withdrawal()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_available numeric := 0;
BEGIN
  PERFORM public.sync_seller_wallet(NEW.seller_id);

  SELECT available_balance
  INTO v_available
  FROM public.seller_wallets
  WHERE seller_id = NEW.seller_id;

  IF COALESCE(v_available, 0) < NEW.amount THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;

  UPDATE public.seller_wallets
  SET available_balance = GREATEST(0, available_balance - NEW.amount),
      updated_at = now()
  WHERE seller_id = NEW.seller_id;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_wallet_after_withdrawal_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.sync_seller_wallet(NEW.seller_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS sync_wallet_after_withdrawal_update
  ON public.seller_withdrawals;
CREATE TRIGGER sync_wallet_after_withdrawal_update
AFTER UPDATE ON public.seller_withdrawals
FOR EACH ROW EXECUTE FUNCTION public.sync_wallet_after_withdrawal_update();

CREATE OR REPLACE FUNCTION public.confirm_order_paid(p_order_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
BEGIN
  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found';
  END IF;
  IF v_order.buyer_id <> auth.uid() THEN
    RAISE EXCEPTION 'Only buyer can confirm payment';
  END IF;
  IF v_order.status <> 'pending_payment' THEN
    RAISE EXCEPTION 'Order cannot be paid from current status';
  END IF;

  UPDATE public.orders
  SET payment_status = 'paid',
      status = 'paid',
      paid_at = COALESCE(paid_at, now()),
      updated_at = now()
  WHERE id = p_order_id;

  PERFORM public.ensure_seller_wallet_exists(v_order.seller_id);
  INSERT INTO public.wallet_transactions (
    user_id,
    order_id,
    type,
    amount,
    balance_bucket,
    description,
    created_by
  )
  VALUES (
    v_order.seller_id,
    v_order.id,
    'order_pending',
    v_order.total_price,
    'pending',
    'Dana pesanan masuk escrow setelah pembayaran buyer.',
    auth.uid()
  );
  PERFORM public.sync_seller_wallet(v_order.seller_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_order_lifecycle_status(
  p_order_id uuid,
  p_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
BEGIN
  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found';
  END IF;

  IF p_status = 'packed' THEN
    IF v_order.seller_id <> auth.uid()
      OR v_order.status NOT IN ('paid', 'pending_payment') THEN
      RAISE EXCEPTION 'Order cannot be packed';
    END IF;
  ELSIF p_status = 'shipped' THEN
    IF v_order.seller_id <> auth.uid() OR v_order.status <> 'packed' THEN
      RAISE EXCEPTION 'Order cannot be shipped';
    END IF;
  ELSIF p_status = 'delivered' THEN
    IF v_order.buyer_id <> auth.uid() OR v_order.status <> 'shipped' THEN
      RAISE EXCEPTION 'Order cannot be marked delivered';
    END IF;
  ELSIF p_status = 'completed' THEN
    IF NOT (
      public.is_admin()
      OR (v_order.buyer_id = auth.uid() AND v_order.status IN ('delivered', 'shipped'))
    ) THEN
      RAISE EXCEPTION 'Order cannot be completed';
    END IF;
  ELSIF p_status = 'cancelled' THEN
    IF auth.uid() NOT IN (v_order.buyer_id, v_order.seller_id)
      OR v_order.status NOT IN ('pending_payment', 'paid') THEN
      RAISE EXCEPTION 'Order cannot be cancelled';
    END IF;
  ELSE
    RAISE EXCEPTION 'Unsupported order status';
  END IF;

  UPDATE public.orders
  SET status = p_status,
      updated_at = now()
  WHERE id = p_order_id;

  IF p_status = 'completed' THEN
    INSERT INTO public.wallet_transactions (
      user_id,
      order_id,
      type,
      amount,
      balance_bucket,
      description,
      created_by
    )
    VALUES (
      v_order.seller_id,
      v_order.id,
      'order_settled',
      v_order.total_price,
      'available',
      'Dana escrow dicairkan ke saldo aktif seller.',
      auth.uid()
    );
  END IF;

  PERFORM public.sync_seller_wallet(v_order.seller_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.request_order_refund(
  p_order_id uuid,
  p_reason text,
  p_description text,
  p_requested_amount numeric,
  p_evidence_urls text[] DEFAULT '{}'::text[]
)
RETURNS public.order_refund_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_refund public.order_refund_requests%ROWTYPE;
BEGIN
  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found';
  END IF;
  IF v_order.buyer_id <> auth.uid() THEN
    RAISE EXCEPTION 'Only buyer can request refund';
  END IF;
  IF v_order.status NOT IN ('paid', 'packed', 'shipped', 'delivered') THEN
    RAISE EXCEPTION 'Refund cannot be requested for this order status';
  END IF;
  IF p_requested_amount <= 0 OR p_requested_amount > v_order.total_price THEN
    RAISE EXCEPTION 'Invalid refund amount';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM public.order_refund_requests
    WHERE order_id = p_order_id
      AND status IN ('submitted', 'seller_responded', 'under_review')
  ) THEN
    RAISE EXCEPTION 'Refund request already exists';
  END IF;

  INSERT INTO public.order_refund_requests (
    order_id,
    buyer_id,
    seller_id,
    reason,
    description,
    requested_amount,
    evidence_urls
  )
  VALUES (
    v_order.id,
    v_order.buyer_id,
    v_order.seller_id,
    trim(p_reason),
    trim(p_description),
    p_requested_amount,
    COALESCE(p_evidence_urls, '{}'::text[])
  )
  RETURNING * INTO v_refund;

  UPDATE public.orders
  SET status = 'disputed',
      updated_at = now()
  WHERE id = p_order_id;

  INSERT INTO public.wallet_transactions (
    user_id,
    order_id,
    refund_id,
    type,
    amount,
    balance_bucket,
    description,
    created_by
  )
  VALUES (
    v_order.seller_id,
    v_order.id,
    v_refund.id,
    'refund_hold',
    v_order.total_price,
    'disputed',
    'Dana pesanan ditahan karena buyer mengajukan refund.',
    auth.uid()
  );

  PERFORM public.sync_seller_wallet(v_order.seller_id);
  RETURN v_refund;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_resolve_refund(
  p_refund_id uuid,
  p_decision text,
  p_approved_amount numeric DEFAULT 0,
  p_admin_note text DEFAULT NULL
)
RETURNS public.order_refund_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_refund public.order_refund_requests%ROWTYPE;
  v_order public.orders%ROWTYPE;
  v_status text;
  v_approved numeric;
  v_seller_release numeric;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can resolve refunds';
  END IF;

  SELECT * INTO v_refund
  FROM public.order_refund_requests
  WHERE id = p_refund_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Refund request not found';
  END IF;
  IF v_refund.status NOT IN ('submitted', 'seller_responded', 'under_review') THEN
    RAISE EXCEPTION 'Refund request already resolved';
  END IF;

  SELECT * INTO v_order
  FROM public.orders
  WHERE id = v_refund.order_id
  FOR UPDATE;

  IF p_decision = 'approved' THEN
    v_status := 'approved';
    v_approved := LEAST(v_refund.requested_amount, v_order.total_price);
  ELSIF p_decision = 'partially_approved' THEN
    v_status := 'partially_approved';
    v_approved := LEAST(GREATEST(COALESCE(p_approved_amount, 0), 0), v_order.total_price);
    IF v_approved <= 0 OR v_approved >= v_order.total_price THEN
      RAISE EXCEPTION 'Partial refund amount must be between 0 and order total';
    END IF;
  ELSIF p_decision = 'rejected' THEN
    v_status := 'rejected';
    v_approved := 0;
  ELSE
    RAISE EXCEPTION 'Invalid refund decision';
  END IF;

  UPDATE public.order_refund_requests
  SET status = v_status,
      approved_amount = v_approved,
      admin_note = NULLIF(trim(COALESCE(p_admin_note, '')), ''),
      resolved_by = auth.uid(),
      resolved_at = now(),
      updated_at = now()
  WHERE id = p_refund_id
  RETURNING * INTO v_refund;

  v_seller_release := GREATEST(0, v_order.total_price - v_approved);

  IF v_status = 'approved' THEN
    UPDATE public.orders
    SET status = 'refunded',
        updated_at = now()
    WHERE id = v_order.id;
  ELSIF v_status = 'partially_approved' THEN
    UPDATE public.orders
    SET status = 'partially_refunded',
        updated_at = now()
    WHERE id = v_order.id;
  ELSE
    UPDATE public.orders
    SET status = 'completed',
        updated_at = now()
    WHERE id = v_order.id;
  END IF;

  IF v_approved > 0 THEN
    INSERT INTO public.wallet_transactions (
      user_id,
      order_id,
      refund_id,
      type,
      amount,
      balance_bucket,
      description,
      created_by
    )
    VALUES (
      v_order.buyer_id,
      v_order.id,
      v_refund.id,
      'refund_approved',
      v_approved,
      'refund',
      'Refund buyer disetujui admin.',
      auth.uid()
    );
  END IF;

  IF v_seller_release > 0 THEN
    INSERT INTO public.wallet_transactions (
      user_id,
      order_id,
      refund_id,
      type,
      amount,
      balance_bucket,
      description,
      created_by
    )
    VALUES (
      v_order.seller_id,
      v_order.id,
      v_refund.id,
      CASE WHEN v_status = 'rejected'
        THEN 'refund_rejected_release'
        ELSE 'refund_partial_release'
      END,
      v_seller_release,
      'available',
      'Sisa dana escrow dicairkan ke seller setelah keputusan refund.',
      auth.uid()
    );
  END IF;

  PERFORM public.sync_seller_wallet(v_order.seller_id);
  RETURN v_refund;
END;
$$;

CREATE OR REPLACE FUNCTION public.fetch_admin_refund_requests(
  p_limit integer DEFAULT 30,
  p_offset integer DEFAULT 0
)
RETURNS SETOF public.order_refund_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can read refund requests';
  END IF;

  RETURN QUERY
  SELECT r.*
  FROM public.order_refund_requests r
  ORDER BY r.created_at DESC
  LIMIT GREATEST(p_limit, 0)
  OFFSET GREATEST(p_offset, 0);
END;
$$;
