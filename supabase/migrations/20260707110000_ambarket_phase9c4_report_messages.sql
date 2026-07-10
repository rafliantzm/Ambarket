-- Add new fields to public.reports
ALTER TABLE public.reports 
ADD COLUMN IF NOT EXISTS final_resolution text,
ADD COLUMN IF NOT EXISTS resolved_by uuid REFERENCES public.profiles(id);

-- Update status check constraint to include 'in_discussion'
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_status_check;
ALTER TABLE public.reports ADD CONSTRAINT reports_status_check 
CHECK (status IN ('pending', 'reviewed', 'in_discussion', 'resolved', 'rejected'));

-- Create public.report_messages table
CREATE TABLE IF NOT EXISTS public.report_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id uuid REFERENCES public.reports(id) ON DELETE CASCADE NOT NULL,
    sender_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    sender_role text NOT NULL CHECK (sender_role IN ('user', 'admin')),
    message text NOT NULL,
    attachment_url text,
    created_at timestamptz DEFAULT now() NOT NULL
);

-- Enable RLS for report_messages
ALTER TABLE public.report_messages ENABLE ROW LEVEL SECURITY;

-- Policy: Users can select their own report messages
CREATE POLICY "Users can select their own report messages"
ON public.report_messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.reports 
        WHERE public.reports.id = report_id 
        AND public.reports.reporter_id = auth.uid()
    )
);

-- Policy: Users can insert messages to their own reports if not resolved/rejected
CREATE POLICY "Users can insert messages to their own reports"
ON public.report_messages FOR INSERT
WITH CHECK (
    sender_id = auth.uid() AND
    sender_role = 'user' AND
    EXISTS (
        SELECT 1 FROM public.reports 
        WHERE public.reports.id = report_id 
        AND public.reports.reporter_id = auth.uid()
        AND public.reports.status NOT IN ('resolved', 'rejected')
    )
);

-- Policy: Admins can select all report messages
CREATE POLICY "Admins can select all report messages"
ON public.report_messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Policy: Admins can insert messages to any report
CREATE POLICY "Admins can insert messages to any report"
ON public.report_messages FOR INSERT
WITH CHECK (
    sender_id = auth.uid() AND
    sender_role = 'admin' AND
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Allow admin to update report final_resolution and status
-- Drop existing update policy if any to recreate clearly
DROP POLICY IF EXISTS "Admins can update reports" ON public.reports;
CREATE POLICY "Admins can update reports"
ON public.reports FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin'
    )
);
