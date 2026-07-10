-- Phase 7A: Hardening Audit

-- 1. Prevent empty messages
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'messages_message_check'
      AND conrelid = 'public.messages'::regclass
  ) THEN
    ALTER TABLE public.messages ADD CONSTRAINT messages_message_check CHECK (trim(message) <> '');
  END IF;
END $$;

-- 2. Prevent buyer from making offer on their own product (already enforced by RLS, but a DB constraint adds another layer)
-- Let's ensure offer_price is strictly positive (already checked in offers table creation)

-- 3. Prevent empty report reason
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'reports_reason_check'
      AND conrelid = 'public.reports'::regclass
  ) THEN
    ALTER TABLE public.reports ADD CONSTRAINT reports_reason_check CHECK (trim(reason) <> '');
  END IF;
END $$;

-- 4. Prevent duplicate checkout was already done via unique(offer_id) in orders
