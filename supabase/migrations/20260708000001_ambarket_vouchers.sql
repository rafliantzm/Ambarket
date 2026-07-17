-- 20260708000001_ambarket_vouchers.sql

-- 1. Create vouchers table
CREATE TABLE IF NOT EXISTS public.vouchers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  code text UNIQUE NOT NULL,
  type text NOT NULL, -- 'percent', 'flat', 'flat_shipping'
  discount_value numeric NOT NULL,
  min_purchase numeric NOT NULL DEFAULT 0,
  max_discount numeric,
  expires_at timestamptz,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2. Create user_vouchers table
CREATE TABLE IF NOT EXISTS public.user_vouchers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  voucher_id uuid REFERENCES public.vouchers(id) ON DELETE CASCADE NOT NULL,
  is_used boolean NOT NULL DEFAULT false,
  claimed_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, voucher_id)
);

-- 3. Enable RLS
ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_vouchers ENABLE ROW LEVEL SECURITY;

-- 4. Policies for vouchers
-- Anyone can view active vouchers
DROP POLICY IF EXISTS "Anyone can view active vouchers" ON public.vouchers;
CREATE POLICY "Anyone can view active vouchers"
  ON public.vouchers FOR SELECT
  USING (is_active = true OR (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  ));

-- Only admins can insert/update vouchers
DROP POLICY IF EXISTS "Admins can insert vouchers" ON public.vouchers;
CREATE POLICY "Admins can insert vouchers"
  ON public.vouchers FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

DROP POLICY IF EXISTS "Admins can update vouchers" ON public.vouchers;
CREATE POLICY "Admins can update vouchers"
  ON public.vouchers FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- 5. Policies for user_vouchers
DROP POLICY IF EXISTS "Users can view own claimed vouchers" ON public.user_vouchers;
CREATE POLICY "Users can view own claimed vouchers"
  ON public.user_vouchers FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can claim vouchers" ON public.user_vouchers;
CREATE POLICY "Users can claim vouchers"
  ON public.user_vouchers FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own claimed vouchers (mark used)" ON public.user_vouchers;
CREATE POLICY "Users can update own claimed vouchers (mark used)"
  ON public.user_vouchers FOR UPDATE
  USING (auth.uid() = user_id);

-- 6. RPC for Admin to create voucher and notify all users
CREATE OR REPLACE FUNCTION public.create_voucher_with_notifications(
  p_title text,
  p_description text,
  p_code text,
  p_type text,
  p_discount_value numeric,
  p_min_purchase numeric,
  p_max_discount numeric,
  p_expires_at timestamptz
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_voucher_id uuid;
  v_admin_role text;
BEGIN
  -- Verify caller is admin
  SELECT role INTO v_admin_role FROM public.profiles WHERE id = auth.uid();
  IF v_admin_role != 'admin' THEN
    RAISE EXCEPTION 'Only admins can create vouchers.';
  END IF;

  -- Insert voucher
  INSERT INTO public.vouchers (
    title, description, code, type, discount_value, min_purchase, max_discount, expires_at
  ) VALUES (
    p_title, p_description, p_code, p_type, p_discount_value, p_min_purchase, p_max_discount, p_expires_at
  ) RETURNING id INTO v_voucher_id;

  -- Create notifications for all users
  INSERT INTO public.notifications (
    user_id, type, title, body, related_type, related_id
  )
  SELECT
    id,
    'voucher',
    'Kupon Baru: ' || p_title,
    p_description,
    'voucher',
    v_voucher_id
  FROM public.profiles
  WHERE role != 'admin'; -- Optional: exclude admins themselves if you want

  RETURN v_voucher_id;
END;
$$;
