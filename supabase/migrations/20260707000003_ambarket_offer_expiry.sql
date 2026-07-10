-- Migration to add accepted_at and expires_at to offers table
ALTER TABLE public.offers ADD COLUMN IF NOT EXISTS accepted_at timestamp with time zone;
ALTER TABLE public.offers ADD COLUMN IF NOT EXISTS expires_at timestamp with time zone;
