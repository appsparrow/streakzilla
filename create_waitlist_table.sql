-- Create waitlist responses table for collecting user feedback
CREATE TABLE IF NOT EXISTS public.sz_waitlist_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  name TEXT,
  feedback TEXT,
  feature_interests TEXT[], -- Array of selected features
  expectations TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  user_agent TEXT,
  referrer TEXT
);

-- Create index on email for quick lookups
CREATE INDEX IF NOT EXISTS idx_waitlist_email ON public.sz_waitlist_responses(email);
CREATE INDEX IF NOT EXISTS idx_waitlist_created_at ON public.sz_waitlist_responses(created_at DESC);

-- Enable RLS (Row Level Security)
ALTER TABLE public.sz_waitlist_responses ENABLE ROW LEVEL SECURITY;

-- Allow anyone to insert (for public waitlist form)
CREATE POLICY "Allow public inserts" ON public.sz_waitlist_responses
  FOR INSERT
  WITH CHECK (true);

-- Only allow authenticated users to view (for admin dashboard)
CREATE POLICY "Allow authenticated users to view" ON public.sz_waitlist_responses
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Add comment to table
COMMENT ON TABLE public.sz_waitlist_responses IS 'Stores waitlist responses and user feedback from the landing page';

