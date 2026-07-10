-- 20260708000000_ambarket_wallet_rpcs.sql

-- 1. Ensure seller wallet exists
CREATE OR REPLACE FUNCTION ensure_seller_wallet_exists(p_seller_id UUID)
RETURNS void AS $$
BEGIN
  INSERT INTO public.seller_wallets (seller_id, available_balance, pending_balance, total_earning)
  VALUES (p_seller_id, 0, 0, 0)
  ON CONFLICT (seller_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Sync seller wallet balance and earnings
CREATE OR REPLACE FUNCTION sync_seller_wallet(p_seller_id UUID)
RETURNS void AS $$
DECLARE
  v_total_revenue numeric;
  v_withdrawn numeric;
  v_pending numeric;
BEGIN
  -- 1. Ensure wallet exists
  PERFORM ensure_seller_wallet_exists(p_seller_id);

  -- 2. Calculate total revenue from completed orders
  SELECT COALESCE(SUM(total_price), 0) INTO v_total_revenue
  FROM public.orders
  WHERE seller_id = p_seller_id AND status = 'completed';

  -- 3. Calculate withdrawals
  SELECT COALESCE(SUM(amount), 0) INTO v_pending
  FROM public.seller_withdrawals
  WHERE seller_id = p_seller_id AND status = 'pending';

  SELECT COALESCE(SUM(amount), 0) INTO v_withdrawn
  FROM public.seller_withdrawals
  WHERE seller_id = p_seller_id AND status = 'approved_dummy';

  -- 4. Update the wallet balances
  -- available_balance = total_revenue - pending - withdrawn
  UPDATE public.seller_wallets
  SET total_earning = v_total_revenue,
      pending_balance = v_pending,
      available_balance = GREATEST(0, v_total_revenue - v_pending - v_withdrawn),
      updated_at = now()
  WHERE seller_id = p_seller_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
