-- Migration: Create news_events table for telemetry tracking
-- Created: Saturday, October 25, 2025 - 16:52 UTC
-- Purpose: Track user events and analytics for crav-news-compare application

-- Create news_events table
CREATE TABLE IF NOT EXISTS public.news_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    org_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id TEXT NOT NULL,
    event_name TEXT NOT NULL,
    properties JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_news_events_org_id ON public.news_events(org_id);
CREATE INDEX IF NOT EXISTS idx_news_events_user_id ON public.news_events(user_id);
CREATE INDEX IF NOT EXISTS idx_news_events_session_id ON public.news_events(session_id);
CREATE INDEX IF NOT EXISTS idx_news_events_event_name ON public.news_events(event_name);
CREATE INDEX IF NOT EXISTS idx_news_events_created_at ON public.news_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_events_properties ON public.news_events USING GIN (properties);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS set_updated_at ON public.news_events;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.news_events
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Enable Row Level Security
ALTER TABLE public.news_events ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own events" ON public.news_events;
DROP POLICY IF EXISTS "Users can insert their own events" ON public.news_events;
DROP POLICY IF EXISTS "Service role can manage all events" ON public.news_events;
DROP POLICY IF EXISTS "Org admins can view org events" ON public.news_events;

-- RLS Policies
CREATE POLICY "Users can view their own events"
    ON public.news_events
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own events"
    ON public.news_events
    FOR INSERT
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Service role can manage all events"
    ON public.news_events
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

CREATE POLICY "Org admins can view org events"
    ON public.news_events
    FOR SELECT
    USING (
        org_id IN (
            SELECT organization_id 
            FROM public.organization_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

-- Grant permissions
GRANT SELECT, INSERT ON public.news_events TO authenticated;
GRANT ALL ON public.news_events TO service_role;

-- Add comment
COMMENT ON TABLE public.news_events IS 'Stores telemetry and analytics events for the news comparison application';
