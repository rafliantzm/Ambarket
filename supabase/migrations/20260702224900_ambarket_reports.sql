-- Create reports table
CREATE TABLE public.reports (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    target_type text NOT NULL CHECK (target_type IN ('product', 'user', 'review')),
    target_id uuid NOT NULL,
    reason text NOT NULL CHECK (reason IN ('fraud', 'fake_product', 'prohibited_item', 'inappropriate_content', 'spam', 'harassment', 'other')),
    description text,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'rejected')),
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    resolved_at timestamptz,
    CONSTRAINT unique_reporter_target UNIQUE (reporter_id, target_type, target_id)
);

-- Trigger for updated_at
CREATE TRIGGER on_report_updated
    BEFORE UPDATE ON public.reports
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Enable RLS
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Policy: User can read their own reports
CREATE POLICY "Users can read their own reports"
ON public.reports FOR SELECT
USING (auth.uid() = reporter_id);

-- Policy: Admin can read all reports (assuming admins have role='admin' in profiles)
CREATE POLICY "Admins can read all reports"
ON public.reports FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Policy: User can insert report (reporter_id must be their own uid)
CREATE POLICY "Users can insert reports"
ON public.reports FOR INSERT
WITH CHECK (auth.uid() = reporter_id);

-- Note: No UPDATE or DELETE policies for normal users, so they cannot edit/delete their own reports after submission.
-- Policy: Admin can update reports
CREATE POLICY "Admins can update reports"
ON public.reports FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin'
    )
);
