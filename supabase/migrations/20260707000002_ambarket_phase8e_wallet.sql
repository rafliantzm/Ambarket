-- 20260707_seller_wallet_migration.sql

-- 1. Create seller_wallets table
CREATE TABLE IF NOT EXISTS public.seller_wallets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
  available_balance numeric DEFAULT 0 NOT NULL,
  pending_balance numeric DEFAULT 0 NOT NULL,
  total_earning numeric DEFAULT 0 NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- RLS for seller_wallets
ALTER TABLE public.seller_wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Sellers can view own wallet" 
  ON public.seller_wallets 
  FOR SELECT 
  USING (auth.uid() = seller_id);

-- Sellers cannot update wallet directly, so no update policy.
-- Note: insert will be handled by the repository using supabase RPC if needed, 
-- but actually we'll just allow insert for creating the wallet if it doesn't exist.
CREATE POLICY "Sellers can insert own wallet" 
  ON public.seller_wallets 
  FOR INSERT 
  WITH CHECK (auth.uid() = seller_id);

-- 2. Create seller_withdrawals table
CREATE TABLE IF NOT EXISTS public.seller_withdrawals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  amount numeric NOT NULL CHECK (amount > 0),
  status text DEFAULT 'pending' NOT NULL CHECK (status in ('pending', 'approved_dummy', 'rejected_dummy')),
  bank_name text NOT NULL,
  account_number text NOT NULL,
  account_holder text NOT NULL,
  note text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- RLS for seller_withdrawals
ALTER TABLE public.seller_withdrawals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Sellers can view own withdrawals" 
  ON public.seller_withdrawals 
  FOR SELECT 
  USING (auth.uid() = seller_id);

CREATE POLICY "Sellers can insert own withdrawals" 
  ON public.seller_withdrawals 
  FOR INSERT 
  WITH CHECK (auth.uid() = seller_id);

-- Admins can view and update withdrawals (Assuming admin role logic)
-- CREATE POLICY "Admins can update withdrawals" ON public.seller_withdrawals FOR UPDATE USING (is_admin());

-- 3. Create Trigger to process withdrawal and adjust wallet balance
CREATE OR REPLACE FUNCTION process_dummy_withdrawal()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if wallet exists
  IF NOT EXISTS (SELECT 1 FROM public.seller_wallets WHERE seller_id = NEW.seller_id) THEN
    RAISE EXCEPTION 'Wallet not found';
  END IF;

  -- Check available balance
  IF (SELECT available_balance FROM public.seller_wallets WHERE seller_id = NEW.seller_id) < NEW.amount THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;

  -- Deduct from available balance, add to pending balance
  UPDATE public.seller_wallets
  SET available_balance = available_balance - NEW.amount,
      pending_balance = pending_balance + NEW.amount,
      updated_at = now()
  WHERE seller_id = NEW.seller_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Bind Trigger to insert event
DROP TRIGGER IF EXISTS on_withdrawal_request ON public.seller_withdrawals;
CREATE TRIGGER on_withdrawal_request
BEFORE INSERT ON public.seller_withdrawals
FOR EACH ROW EXECUTE FUNCTION process_dummy_withdrawal();

-- (Optional) Dummy Trigger for approved/rejected logic to revert/commit balance.
-- For MVP we only handle 'pending' during insert.
