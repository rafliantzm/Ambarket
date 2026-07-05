-- Phase 7A: Hardening Audit

-- 1. Prevent empty messages
ALTER TABLE public.messages ADD CONSTRAINT messages_message_check CHECK (trim(message) <> '');

-- 2. Prevent buyer from making offer on their own product (already enforced by RLS, but a DB constraint adds another layer)
-- Let's ensure offer_price is strictly positive (already checked in offers table creation)

-- 3. Prevent empty report reason
ALTER TABLE public.reports ADD CONSTRAINT reports_reason_check CHECK (trim(reason) <> '');

-- 4. Prevent duplicate checkout was already done via unique(offer_id) in orders
