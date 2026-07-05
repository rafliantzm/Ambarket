-- Trigger Function to block suspended users
CREATE OR REPLACE FUNCTION public.check_user_not_suspended()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_suspended = true) THEN
      RAISE EXCEPTION 'User is suspended';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- Apply trigger to tables where user creates/updates content
DROP TRIGGER IF EXISTS check_suspended_products ON public.products;
CREATE TRIGGER check_suspended_products
  BEFORE INSERT OR UPDATE ON public.products
  FOR EACH ROW EXECUTE PROCEDURE public.check_user_not_suspended();

DROP TRIGGER IF EXISTS check_suspended_offers ON public.offers;
CREATE TRIGGER check_suspended_offers
  BEFORE INSERT OR UPDATE ON public.offers
  FOR EACH ROW EXECUTE PROCEDURE public.check_user_not_suspended();

DROP TRIGGER IF EXISTS check_suspended_messages ON public.messages;
CREATE TRIGGER check_suspended_messages
  BEFORE INSERT ON public.messages
  FOR EACH ROW EXECUTE PROCEDURE public.check_user_not_suspended();

DROP TRIGGER IF EXISTS check_suspended_orders ON public.orders;
CREATE TRIGGER check_suspended_orders
  BEFORE INSERT OR UPDATE ON public.orders
  FOR EACH ROW EXECUTE PROCEDURE public.check_user_not_suspended();

DROP TRIGGER IF EXISTS check_suspended_reviews ON public.reviews;
CREATE TRIGGER check_suspended_reviews
  BEFORE INSERT ON public.reviews
  FOR EACH ROW EXECUTE PROCEDURE public.check_user_not_suspended();

DROP TRIGGER IF EXISTS check_suspended_reports ON public.reports;
CREATE TRIGGER check_suspended_reports
  BEFORE INSERT ON public.reports
  FOR EACH ROW EXECUTE PROCEDURE public.check_user_not_suspended();

-- Also ensure Admins can read all reviews if not already explicitly stated
DROP POLICY IF EXISTS "Admins can read all reviews" ON public.reviews;
CREATE POLICY "Admins can read all reviews"
ON public.reviews FOR SELECT
USING (public.is_admin());
