-- CR AudioViz AI - News Comparison Platform Database Schema
-- Conservative vs Liberal News Comparison
-- 22 Tables for Complete Platform

-- ============================================
-- 1. ORGANIZATIONS
-- ============================================

CREATE TABLE IF NOT EXISTS news_orgs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_orgs_slug ON news_orgs(slug);

-- ============================================
-- 2. ORG MEMBERS
-- ============================================

CREATE TABLE IF NOT EXISTS news_org_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(org_id, user_id)
);

CREATE INDEX idx_news_org_members_org ON news_org_members(org_id);
CREATE INDEX idx_news_org_members_user ON news_org_members(user_id);

-- ============================================
-- 3. PLANS
-- ============================================

CREATE TABLE IF NOT EXISTS news_plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price_monthly INTEGER NOT NULL DEFAULT 0,
  stripe_price_id TEXT,
  features JSONB DEFAULT '{}',
  monthly_quota JSONB DEFAULT '{}',
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default plans
INSERT INTO news_plans (id, name, description, price_monthly, features, monthly_quota, sort_order, is_active)
VALUES 
  ('free', 'Free', 'Basic news comparison', 0, 
   '{"compare": true, "save": true, "api_access": false, "international": false, "composer": false}',
   '{"articles_saved": 10, "api_calls": 0, "international_access": 0}',
   1, true),
  ('pro', 'Pro', 'Advanced features for professionals', 2900,
   '{"compare": true, "save": true, "api_access": true, "international": true, "composer": true}',
   '{"articles_saved": -1, "api_calls": 10000, "international_access": -1}',
   2, true),
  ('enterprise', 'Enterprise', 'Unlimited access for organizations', 9900,
   '{"compare": true, "save": true, "api_access": true, "international": true, "composer": true, "white_label": true}',
   '{"articles_saved": -1, "api_calls": -1, "international_access": -1}',
   3, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 4. SUBSCRIPTIONS
-- ============================================

CREATE TABLE IF NOT EXISTS news_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  plan_id TEXT NOT NULL REFERENCES news_plans(id),
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(org_id)
);

CREATE INDEX idx_news_subscriptions_org ON news_subscriptions(org_id);
CREATE INDEX idx_news_subscriptions_stripe_customer ON news_subscriptions(stripe_customer_id);
CREATE INDEX idx_news_subscriptions_status ON news_subscriptions(status);

-- ============================================
-- 5. USAGE COUNTERS
-- ============================================

CREATE TABLE IF NOT EXISTS news_usage_counters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  metric TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  period_start TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(org_id, metric, period_start)
);

CREATE INDEX idx_news_usage_counters_org_metric ON news_usage_counters(org_id, metric);
CREATE INDEX idx_news_usage_counters_period ON news_usage_counters(period_start);

-- ============================================
-- 6. RATE LIMITS
-- ============================================

CREATE TABLE IF NOT EXISTS news_rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL,
  bucket TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  window_start TIMESTAMPTZ NOT NULL,
  window_end TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(key, bucket, window_start)
);

CREATE INDEX idx_news_rate_limits_key_bucket ON news_rate_limits(key, bucket);
CREATE INDEX idx_news_rate_limits_window ON news_rate_limits(window_end);

-- ============================================
-- 7. NEWS SOURCES
-- ============================================

CREATE TABLE IF NOT EXISTS news_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  bias TEXT NOT NULL CHECK (bias IN ('conservative', 'liberal', 'neutral')),
  country TEXT DEFAULT 'US',
  language TEXT DEFAULT 'en',
  is_active BOOLEAN DEFAULT true,
  reliability_score DECIMAL(3,2) DEFAULT 0.5,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_sources_bias ON news_sources(bias);
CREATE INDEX idx_news_sources_country ON news_sources(country);
CREATE INDEX idx_news_sources_active ON news_sources(is_active);

-- ============================================
-- 8. ARTICLES
-- ============================================

CREATE TABLE IF NOT EXISTS news_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id UUID NOT NULL REFERENCES news_sources(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  url TEXT NOT NULL UNIQUE,
  content TEXT,
  author TEXT,
  published_at TIMESTAMPTZ,
  fetched_at TIMESTAMPTZ DEFAULT NOW(),
  image_url TEXT,
  bias TEXT NOT NULL CHECK (bias IN ('conservative', 'liberal', 'neutral')),
  sentiment_score DECIMAL(3,2),
  keywords TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_articles_source ON news_articles(source_id);
CREATE INDEX idx_news_articles_published ON news_articles(published_at DESC);
CREATE INDEX idx_news_articles_bias ON news_articles(bias);
CREATE INDEX idx_news_articles_keywords ON news_articles USING GIN(keywords);

-- ============================================
-- 9. EVENTS (Clustered Topics)
-- ============================================

CREATE TABLE IF NOT EXISTS news_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  keywords TEXT[],
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_events_dates ON news_events(start_date, end_date);
CREATE INDEX idx_news_events_active ON news_events(is_active);
CREATE INDEX idx_news_events_keywords ON news_events USING GIN(keywords);

-- ============================================
-- 10. EVENT ARTICLES (Many-to-Many)
-- ============================================

CREATE TABLE IF NOT EXISTS news_event_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES news_events(id) ON DELETE CASCADE,
  article_id UUID NOT NULL REFERENCES news_articles(id) ON DELETE CASCADE,
  relevance_score DECIMAL(3,2) DEFAULT 0.5,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, article_id)
);

CREATE INDEX idx_news_event_articles_event ON news_event_articles(event_id);
CREATE INDEX idx_news_event_articles_article ON news_event_articles(article_id);

-- ============================================
-- 11. SAVED ARTICLES
-- ============================================

CREATE TABLE IF NOT EXISTS news_saved_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  article_id UUID NOT NULL REFERENCES news_articles(id) ON DELETE CASCADE,
  notes TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, article_id)
);

CREATE INDEX idx_news_saved_articles_user ON news_saved_articles(user_id);
CREATE INDEX idx_news_saved_articles_article ON news_saved_articles(article_id);
CREATE INDEX idx_news_saved_articles_tags ON news_saved_articles USING GIN(tags);

-- ============================================
-- 12. COMPARISONS
-- ============================================

CREATE TABLE IF NOT EXISTS news_comparisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  conservative_article_id UUID REFERENCES news_articles(id) ON DELETE CASCADE,
  liberal_article_id UUID REFERENCES news_articles(id) ON DELETE CASCADE,
  notes TEXT,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_comparisons_user ON news_comparisons(user_id);
CREATE INDEX idx_news_comparisons_public ON news_comparisons(is_public);

-- ============================================
-- 13. DIFF RESULTS
-- ============================================

CREATE TABLE IF NOT EXISTS news_diff_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comparison_id UUID NOT NULL REFERENCES news_comparisons(id) ON DELETE CASCADE,
  diff_data JSONB NOT NULL,
  similarity_score DECIMAL(3,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_diff_results_comparison ON news_diff_results(comparison_id);

-- ============================================
-- 14. COMPOSER OUTPUTS
-- ============================================

CREATE TABLE IF NOT EXISTS news_composer_outputs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('newsletter', 'social', 'email', 'blog')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  source_articles UUID[],
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_composer_outputs_user ON news_composer_outputs(user_id);
CREATE INDEX idx_news_composer_outputs_type ON news_composer_outputs(type);

-- ============================================
-- 15. SHORTLINKS
-- ============================================

CREATE TABLE IF NOT EXISTS news_shortlinks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  code TEXT UNIQUE NOT NULL,
  target_url TEXT NOT NULL,
  clicks INTEGER DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_shortlinks_code ON news_shortlinks(code);
CREATE INDEX idx_news_shortlinks_user ON news_shortlinks(user_id);

-- ============================================
-- 16. API KEYS
-- ============================================

CREATE TABLE IF NOT EXISTS news_api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  key_hash TEXT NOT NULL UNIQUE,
  key_prefix TEXT NOT NULL,
  last_used_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

CREATE INDEX idx_news_api_keys_org ON news_api_keys(org_id);
CREATE INDEX idx_news_api_keys_hash ON news_api_keys(key_hash);
CREATE INDEX idx_news_api_keys_active ON news_api_keys(is_active);

-- ============================================
-- 17. API LOGS
-- ============================================

CREATE TABLE IF NOT EXISTS news_api_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key_id UUID REFERENCES news_api_keys(id) ON DELETE SET NULL,
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL,
  status_code INTEGER NOT NULL,
  response_time_ms INTEGER,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_api_logs_key ON news_api_logs(api_key_id);
CREATE INDEX idx_news_api_logs_created ON news_api_logs(created_at DESC);
CREATE INDEX idx_news_api_logs_endpoint ON news_api_logs(endpoint);

-- ============================================
-- 18. TELEMETRY EVENTS
-- ============================================

CREATE TABLE IF NOT EXISTS news_telemetry_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  org_id UUID REFERENCES news_orgs(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  event_data JSONB DEFAULT '{}',
  session_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_telemetry_user ON news_telemetry_events(user_id);
CREATE INDEX idx_news_telemetry_org ON news_telemetry_events(org_id);
CREATE INDEX idx_news_telemetry_type ON news_telemetry_events(event_type);
CREATE INDEX idx_news_telemetry_created ON news_telemetry_events(created_at DESC);

-- ============================================
-- 19. ANALYTICS AGGREGATES
-- ============================================

CREATE TABLE IF NOT EXISTS news_analytics_daily (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID REFERENCES news_orgs(id) ON DELETE CASCADE,
  metric TEXT NOT NULL,
  value DECIMAL NOT NULL,
  dimensions JSONB DEFAULT '{}',
  date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(org_id, metric, date, dimensions)
);

CREATE INDEX idx_news_analytics_org_date ON news_analytics_daily(org_id, date DESC);
CREATE INDEX idx_news_analytics_metric ON news_analytics_daily(metric);

-- ============================================
-- 20. WEBHOOKS
-- ============================================

CREATE TABLE IF NOT EXISTS news_webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  events TEXT[] NOT NULL,
  secret TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

CREATE INDEX idx_news_webhooks_org ON news_webhooks(org_id);
CREATE INDEX idx_news_webhooks_active ON news_webhooks(is_active);

-- ============================================
-- 21. WEBHOOK DELIVERIES
-- ============================================

CREATE TABLE IF NOT EXISTS news_webhook_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_id UUID NOT NULL REFERENCES news_webhooks(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  status_code INTEGER,
  response_body TEXT,
  attempts INTEGER DEFAULT 0,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_webhook_deliveries_webhook ON news_webhook_deliveries(webhook_id);
CREATE INDEX idx_news_webhook_deliveries_created ON news_webhook_deliveries(created_at DESC);

-- ============================================
-- 22. GUARDRAILS / ABUSE DETECTION
-- ============================================

CREATE TABLE IF NOT EXISTS news_abuse_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  org_id UUID REFERENCES news_orgs(id) ON DELETE CASCADE,
  report_type TEXT NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  details JSONB DEFAULT '{}',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'ignored')),
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_news_abuse_reports_user ON news_abuse_reports(user_id);
CREATE INDEX idx_news_abuse_reports_org ON news_abuse_reports(org_id);
CREATE INDEX idx_news_abuse_reports_status ON news_abuse_reports(status);
CREATE INDEX idx_news_abuse_reports_severity ON news_abuse_reports(severity);

-- ============================================
-- RPC FUNCTIONS
-- ============================================

-- Function to bump usage counters
CREATE OR REPLACE FUNCTION bump_news_usage(
  p_org UUID,
  p_metric TEXT,
  p_inc INTEGER DEFAULT 1
) RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
  v_period_start TIMESTAMPTZ;
BEGIN
  v_period_start := date_trunc('month', NOW());
  
  INSERT INTO news_usage_counters (org_id, metric, count, period_start)
  VALUES (p_org, p_metric, p_inc, v_period_start)
  ON CONFLICT (org_id, metric, period_start)
  DO UPDATE SET 
    count = news_usage_counters.count + p_inc,
    updated_at = NOW()
  RETURNING count INTO v_count;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Function to bump rate limits
CREATE OR REPLACE FUNCTION bump_news_rate(
  p_key TEXT,
  p_bucket TEXT,
  p_inc INTEGER DEFAULT 1,
  p_window_secs INTEGER DEFAULT 60
) RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
  v_window_start TIMESTAMPTZ;
  v_window_end TIMESTAMPTZ;
BEGIN
  v_window_start := date_trunc('minute', NOW());
  v_window_end := v_window_start + (p_window_secs || ' seconds')::INTERVAL;
  
  -- Clean old windows
  DELETE FROM news_rate_limits WHERE window_end < NOW();
  
  -- Insert or update
  INSERT INTO news_rate_limits (key, bucket, count, window_start, window_end)
  VALUES (p_key, p_bucket, p_inc, v_window_start, v_window_end)
  ON CONFLICT (key, bucket, window_start)
  DO UPDATE SET 
    count = news_rate_limits.count + p_inc
  RETURNING count INTO v_count;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE news_orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_usage_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_saved_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_comparisons ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_composer_outputs ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_telemetry_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_webhooks ENABLE ROW LEVEL SECURITY;

-- Policies: Users can read their own org data
CREATE POLICY "Users can view their org"
  ON news_orgs FOR SELECT
  USING (id IN (
    SELECT org_id FROM news_org_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view org members"
  ON news_org_members FOR SELECT
  USING (org_id IN (
    SELECT org_id FROM news_org_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view their subscription"
  ON news_subscriptions FOR SELECT
  USING (org_id IN (
    SELECT org_id FROM news_org_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view their saved articles"
  ON news_saved_articles FOR ALL
  USING (user_id = auth.uid());

CREATE POLICY "Users can manage their comparisons"
  ON news_comparisons FOR ALL
  USING (user_id = auth.uid());

CREATE POLICY "Users can view their composer outputs"
  ON news_composer_outputs FOR ALL
  USING (user_id = auth.uid());

-- Public read access for articles and sources
CREATE POLICY "Public read access to articles"
  ON news_articles FOR SELECT
  USING (true);

CREATE POLICY "Public read access to sources"
  ON news_sources FOR SELECT
  USING (true);

CREATE POLICY "Public read access to events"
  ON news_events FOR SELECT
  USING (true);

CREATE POLICY "Public read access to plans"
  ON news_plans FOR SELECT
  USING (true);

-- Service role bypass (for API operations)
CREATE POLICY "Service role bypass on all tables"
  ON news_orgs FOR ALL
  USING (current_setting('role') = 'service_role');

-- ============================================
-- TRIGGERS
-- ============================================

-- Update timestamps trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers to tables with updated_at
CREATE TRIGGER set_updated_at BEFORE UPDATE ON news_orgs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  
CREATE TRIGGER set_updated_at BEFORE UPDATE ON news_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  
CREATE TRIGGER set_updated_at BEFORE UPDATE ON news_subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  
CREATE TRIGGER set_updated_at BEFORE UPDATE ON news_sources
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  
CREATE TRIGGER set_updated_at BEFORE UPDATE ON news_articles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  
CREATE TRIGGER set_updated_at BEFORE UPDATE ON news_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  
CREATE TRIGGER set_updated_at BEFORE UPDATE ON news_comparisons
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  
CREATE TRIGGER set_updated_at BEFORE UPDATE ON news_composer_outputs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- COMPLETE!
-- ============================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';
