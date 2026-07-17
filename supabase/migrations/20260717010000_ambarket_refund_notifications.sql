-- Ensure refund workflow emits role-specific notifications from the
-- authoritative database functions, not only from a best-effort client call.

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
  v_order_code text;
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

  v_order_code := COALESCE(v_order.invoice_number, upper(substr(v_order.id::text, 1, 8)));

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

  INSERT INTO public.notifications (
    user_id,
    type,
    title,
    body,
    related_type,
    related_id
  )
  SELECT
    p.id,
    'refund_requested',
    'Pengajuan Refund Baru',
    format('Buyer mengajukan refund untuk pesanan %s. Mohon tinjau sengketa ini.', v_order_code),
    'refund',
    v_order.id
  FROM public.profiles p
  WHERE p.role = 'admin';

  INSERT INTO public.notifications (
    user_id,
    type,
    title,
    body,
    related_type,
    related_id
  )
  VALUES (
    v_order.seller_id,
    'refund_requested_seller',
    'Refund Diajukan Buyer',
    format('Buyer mengajukan refund untuk pesanan %s. Dana pesanan ditahan sampai admin memberi keputusan.', v_order_code),
    'refund',
    v_order.id
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
  v_order_code text;
  v_buyer_title text;
  v_buyer_body text;
  v_seller_body text;
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
  v_order_code := COALESCE(v_order.invoice_number, upper(substr(v_order.id::text, 1, 8)));

  IF v_status = 'approved' THEN
    UPDATE public.orders
    SET status = 'refunded',
        updated_at = now()
    WHERE id = v_order.id;

    v_buyer_title := 'Refund Disetujui';
    v_buyer_body := format('Refund pesanan %s disetujui penuh oleh admin.', v_order_code);
    v_seller_body := format('Refund pesanan %s disetujui penuh. Dana pesanan dikembalikan ke buyer.', v_order_code);
  ELSIF v_status = 'partially_approved' THEN
    UPDATE public.orders
    SET status = 'partially_refunded',
        updated_at = now()
    WHERE id = v_order.id;

    v_buyer_title := 'Refund Disetujui Sebagian';
    v_buyer_body := format('Refund pesanan %s disetujui sebagian oleh admin.', v_order_code);
    v_seller_body := format('Refund pesanan %s disetujui sebagian. Sisa dana akan masuk ke saldo seller.', v_order_code);
  ELSE
    UPDATE public.orders
    SET status = 'completed',
        updated_at = now()
    WHERE id = v_order.id;

    v_buyer_title := 'Refund Ditolak';
    v_buyer_body := format('Pengajuan refund pesanan %s ditolak oleh admin.', v_order_code);
    v_seller_body := format('Pengajuan refund pesanan %s ditolak. Dana pesanan dicairkan ke saldo seller.', v_order_code);
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

  INSERT INTO public.notifications (
    user_id,
    type,
    title,
    body,
    related_type,
    related_id
  )
  VALUES (
    v_order.buyer_id,
    'refund_' || v_status,
    v_buyer_title,
    v_buyer_body,
    'refund',
    v_order.id
  );

  INSERT INTO public.notifications (
    user_id,
    type,
    title,
    body,
    related_type,
    related_id
  )
  VALUES (
    v_order.seller_id,
    'refund_' || v_status || '_seller',
    'Keputusan Refund',
    v_seller_body,
    'refund',
    v_order.id
  );

  PERFORM public.sync_seller_wallet(v_order.seller_id);
  RETURN v_refund;
END;
$$;
