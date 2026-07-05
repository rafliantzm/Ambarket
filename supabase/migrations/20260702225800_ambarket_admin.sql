-- Helper Function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$;

-- Profile Hardening
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_suspended boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS suspension_reason text,
ADD COLUMN IF NOT EXISTS suspended_at timestamptz;

REVOKE UPDATE ON public.profiles FROM authenticated;
GRANT UPDATE (name, avatar_url, username, phone, address, location, bio, updated_at) ON public.profiles TO authenticated;

-- Products constraint update
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_status_check;
ALTER TABLE public.products ADD CONSTRAINT products_status_check CHECK (status in ('active', 'sold', 'archived', 'reserved', 'hidden', 'rejected'));

-- Product Admin Policy
CREATE POLICY "Admins can update all products"
ON public.products FOR UPDATE
USING (public.is_admin());

-- Reviews Update
ALTER TABLE public.reviews
ADD COLUMN IF NOT EXISTS is_hidden boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS moderation_note text,
ADD COLUMN IF NOT EXISTS moderated_at timestamptz;

CREATE POLICY "Admins can update reviews"
ON public.reviews FOR UPDATE
USING (public.is_admin());

-- Admin Audit Logs
CREATE TABLE public.admin_audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    action text NOT NULL,
    target_type text NOT NULL,
    target_id uuid,
    metadata jsonb,
    created_at timestamptz DEFAULT now() NOT NULL
);

ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can insert audit logs"
ON public.admin_audit_logs FOR INSERT
WITH CHECK (public.is_admin() AND auth.uid() = admin_id);

CREATE POLICY "Admins can read audit logs"
ON public.admin_audit_logs FOR SELECT
USING (public.is_admin());

-- Also update policies on public.reports to use public.is_admin() instead of inline subquery for cleanliness
DROP POLICY IF EXISTS "Admins can read all reports" ON public.reports;
CREATE POLICY "Admins can read all reports"
ON public.reports FOR SELECT
USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can update reports" ON public.reports;
CREATE POLICY "Admins can update reports"
ON public.reports FOR UPDATE
USING (public.is_admin());
