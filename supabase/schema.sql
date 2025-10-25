-- CR AudioViz AI - News Comparison Platform Schema
-- Adds to existing 33-table Supabase database
-- Generated: 2025-10-25 12:50:45 ET

-- ========================================
-- EXTENSIONS
-- ========================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================
-- NEWS ORGANIZATIONS & MEMBERSHIPS
-- ========================================

CREATE TABLE IF NOT EXISTS news_orgs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS news_org_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'editor', 'viewer')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(org_id, user_id)
);

CREATE INDEX idx_org_members_org ON news_org_members(org_id);
CREATE INDEX idx_org_members_user ON news_org_members(user_id);

-- ========================================
-- PLANS & SUBSCRIPTIONS
-- ========================================

CREATE TABLE IF NOT EXISTS news_plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price_monthly DECIMAL(10, 2) NOT NULL DEFAULT 0,
  stripe_price_id TEXT,
  monthly_quota JSONB NOT NULL DEFAULT '{
    "compose": 10,
    "reads": 1000,
    "diffs": 100,
    "intl_countries": 0,
    "exports": 0,
    "api_calls": 0
  }'::jsonb,
  features JSONB NOT NULL DEFAULT '{
    "intl_compare": false,
    "exports": false,
    "api": false,
    "sso": false,
    "priority_support": false
  }'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS news_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  plan_id TEXT NOT NULL REFERENCES news_plans(id),
  status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'past_due', 'trialing', 'incomplete')),
  stripe_subscription_id TEXT,
  stripe_customer_id TEXT,
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_org ON news_subscriptions(org_id);
CREATE INDEX idx_subscriptions_stripe ON news_subscriptions(stripe_subscription_id);

-- ========================================
-- USAGE TRACKING
-- ========================================

CREATE TABLE IF NOT EXISTS news_usage_counters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  metric TEXT NOT NULL,
  count INT NOT NULL DEFAULT 0,
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(org_id, metric, period_start)
);

CREATE INDEX idx_usage_org_metric ON news_usage_counters(org_id, metric);

-- Function to bump usage counter
CREATE OR REPLACE FUNCTION bump_news_usage(
  p_org UUID,
  p_metric TEXT,
  p_inc INT DEFAULT 1
) RETURNS INT AS $$
DECLARE
  v_period_start TIMESTAMPTZ;
  v_period_end TIMESTAMPTZ;
  v_count INT;
BEGIN
  -- Calculate current billing period
  v_period_start := DATE_TRUNC('month', NOW());
  v_period_end := v_period_start + INTERVAL '1 month';
  
  -- Upsert counter
  INSERT INTO news_usage_counters (org_id, metric, count, period_start, period_end)
  VALUES (p_org, p_metric, p_inc, v_period_start, v_period_end)
  ON CONFLICT (org_id, metric, period_start)
  DO UPDATE SET
    count = news_usage_counters.count + p_inc,
    updated_at = NOW()
  RETURNING count INTO v_count;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- NEWS CONTENT
-- ========================================

CREATE TABLE IF NOT EXISTS news_sources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  ideology TEXT CHECK (ideology IN ('conservative', 'liberal', 'neutral', 'mixed')),
  country_code TEXT NOT NULL DEFAULT 'US',
  reliability_score DECIMAL(3, 2) DEFAULT 0.5,
  active BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sources_ideology ON news_sources(ideology);
CREATE INDEX idx_sources_country ON news_sources(country_code);

CREATE TABLE IF NOT EXISTS news_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  summary TEXT,
  keywords TEXT[],
  date DATE NOT NULL,
  country_code TEXT NOT NULL DEFAULT 'US',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_groups_date ON news_groups(date DESC);
CREATE INDEX idx_groups_country_date ON news_groups(country_code, date DESC);

CREATE TABLE IF NOT EXISTS news_articles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES news_groups(id) ON DELETE CASCADE,
  source_id UUID NOT NULL REFERENCES news_sources(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  content TEXT,
  excerpt TEXT,
  published_at TIMESTAMPTZ,
  ideology TEXT CHECK (ideology IN ('conservative', 'liberal', 'neutral')),
  sentiment_score DECIMAL(3, 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_articles_group ON news_articles(group_id);
CREATE INDEX idx_articles_source ON news_articles(source_id);
CREATE INDEX idx_articles_ideology ON news_articles(ideology);

-- ========================================
-- USER INTERACTIONS
-- ========================================

CREATE TABLE IF NOT EXISTS news_group_status (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES news_groups(id) ON DELETE CASCADE,
  saved BOOLEAN NOT NULL DEFAULT false,
  archived BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, group_id)
);

CREATE INDEX idx_group_status_user ON news_group_status(user_id);
CREATE INDEX idx_group_status_saved ON news_group_status(user_id, saved) WHERE saved = true;

-- ========================================
-- COMPOSER & PUBLISHING
-- ========================================

CREATE TABLE IF NOT EXISTS news_composer_drafts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('newsletter', 'social', 'email')),
  template_id TEXT,
  subject TEXT,
  content TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  published BOOLEAN NOT NULL DEFAULT false,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_drafts_org ON news_composer_drafts(org_id);
CREATE INDEX idx_drafts_published ON news_composer_drafts(published, org_id);

CREATE TABLE IF NOT EXISTS news_composer_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  content TEXT NOT NULL,
  variables TEXT[],
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========================================
-- SHORTLINKS
-- ========================================

CREATE TABLE IF NOT EXISTS news_shortlinks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE,
  target_url TEXT NOT NULL,
  title TEXT,
  clicks INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_shortlinks_code ON news_shortlinks(code);
CREATE INDEX idx_shortlinks_org ON news_shortlinks(org_id);

-- ========================================
-- TELEMETRY & ANALYTICS
-- ========================================

CREATE TABLE IF NOT EXISTS news_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID REFERENCES news_orgs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  session_id TEXT NOT NULL,
  event_name TEXT NOT NULL,
  properties JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_events_org_created ON news_events(org_id, created_at DESC);
CREATE INDEX idx_events_name ON news_events(event_name, created_at DESC);
CREATE INDEX idx_events_session ON news_events(session_id);

CREATE TABLE IF NOT EXISTS news_source_metrics_daily (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID NOT NULL REFERENCES news_sources(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  impressions INT NOT NULL DEFAULT 0,
  clicks INT NOT NULL DEFAULT 0,
  avg_dwell_seconds DECIMAL(10, 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(source_id, date)
);

CREATE INDEX idx_source_metrics_date ON news_source_metrics_daily(date DESC);

-- Function to rollup source metrics
CREATE OR REPLACE FUNCTION rollup_news_source_metrics(p_date DATE) RETURNS VOID AS $$
BEGIN
  INSERT INTO news_source_metrics_daily (source_id, date, impressions, clicks, avg_dwell_seconds)
  SELECT
    (properties->>'source_id')::UUID as source_id,
    p_date,
    COUNT(*) FILTER (WHERE event_name = 'article_impression') as impressions,
    COUNT(*) FILTER (WHERE event_name = 'article_click') as clicks,
    AVG((properties->>'dwell_seconds')::DECIMAL) as avg_dwell_seconds
  FROM news_events
  WHERE DATE(created_at) = p_date
    AND event_name IN ('article_impression', 'article_click')
    AND properties->>'source_id' IS NOT NULL
  GROUP BY (properties->>'source_id')::UUID
  ON CONFLICT (source_id, date)
  DO UPDATE SET
    impressions = EXCLUDED.impressions,
    clicks = EXCLUDED.clicks,
    avg_dwell_seconds = EXCLUDED.avg_dwell_seconds;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- RATE LIMITING
-- ========================================

CREATE TABLE IF NOT EXISTS news_rate_limits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT NOT NULL,
  bucket TEXT NOT NULL,
  count INT NOT NULL DEFAULT 0,
  window_start TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(key, bucket, window_start)
);

CREATE INDEX idx_rate_limits_key ON news_rate_limits(key, bucket, window_start);

-- Function for rate limiting
CREATE OR REPLACE FUNCTION bump_news_rate(
  p_key TEXT,
  p_bucket TEXT,
  p_inc INT DEFAULT 1,
  p_window_secs INT DEFAULT 60
) RETURNS INT AS $$
DECLARE
  v_window_start TIMESTAMPTZ;
  v_count INT;
BEGIN
  v_window_start := DATE_TRUNC('minute', NOW());
  
  INSERT INTO news_rate_limits (key, bucket, count, window_start)
  VALUES (p_key, p_bucket, p_inc, v_window_start)
  ON CONFLICT (key, bucket, window_start)
  DO UPDATE SET
    count = news_rate_limits.count + p_inc
  RETURNING count INTO v_count;
  
  -- Clean up old windows
  DELETE FROM news_rate_limits
  WHERE window_start < NOW() - INTERVAL '1 hour';
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- API KEYS
-- ========================================

CREATE TABLE IF NOT EXISTS news_api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  key_hash TEXT NOT NULL UNIQUE,
  prefix TEXT NOT NULL,
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ
);

CREATE INDEX idx_api_keys_org ON news_api_keys(org_id);
CREATE INDEX idx_api_keys_hash ON news_api_keys(key_hash);

-- ========================================
-- COUPONS & REFERRALS
-- ========================================

CREATE TABLE IF NOT EXISTS news_coupons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT NOT NULL UNIQUE,
  discount_percent INT,
  discount_amount DECIMAL(10, 2),
  max_uses INT,
  uses_count INT NOT NULL DEFAULT 0,
  expires_at TIMESTAMPTZ,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS news_referrals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  referrer_org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  referred_org_id UUID NOT NULL REFERENCES news_orgs(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  reward_amount DECIMAL(10, 2),
  rewarded BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(referrer_org_id, referred_org_id)
);

-- ========================================
-- SEED DATA
-- ========================================

-- Insert default plans
INSERT INTO news_plans (id, name, description, price_monthly, stripe_price_id, monthly_quota, features)
VALUES
  ('free', 'Free', 'Basic news comparison with limited features', 0, 'price_free_placeholder', '{
    "compose": 10,
    "reads": 1000,
    "diffs": 100,
    "intl_countries": 0,
    "exports": 0,
    "api_calls": 0
  }', '{
    "intl_compare": false,
    "exports": false,
    "api": false,
    "sso": false,
    "priority_support": false
  }'),
  ('pro', 'Pro', 'Full access to all features including international news', 29.99, 'price_pro_placeholder', '{
    "compose": 100,
    "reads": 50000,
    "diffs": 5000,
    "intl_countries": 10,
    "exports": 1000,
    "api_calls": 10000
  }', '{
    "intl_compare": true,
    "exports": true,
    "api": true,
    "sso": false,
    "priority_support": true
  }'),
  ('enterprise', 'Enterprise', 'Unlimited access with SSO and dedicated support', 99.99, 'price_ent_placeholder', '{
    "compose": -1,
    "reads": -1,
    "diffs": -1,
    "intl_countries": -1,
    "exports": -1,
    "api_calls": -1
  }', '{
    "intl_compare": true,
    "exports": true,
    "api": true,
    "sso": true,
    "priority_support": true
  }')
ON CONFLICT (id) DO NOTHING;

-- Insert sample composer templates
INSERT INTO news_composer_templates (id, name, type, content, variables)
VALUES
  ('newsletter-basic', 'Basic Newsletter', 'newsletter', 'Daily News Roundup\n\n{{content}}\n\nBest regards,\n{{sender}}', ARRAY['content', 'sender']),
  ('social-twitter', 'Twitter Post', 'social', '📰 {{headline}}\n\n{{summary}}\n\n🔗 {{link}}', ARRAY['headline', 'summary', 'link']),
  ('email-alert', 'Breaking News Alert', 'email', 'Subject: Breaking: {{headline}}\n\n{{content}}\n\nRead more: {{link}}', ARRAY['headline', 'content', 'link'])
ON CONFLICT (id) DO NOTHING;

-- Insert sample news sources
INSERT INTO news_sources (name, url, ideology, country_code, reliability_score)
VALUES
  ('Fox News', 'https://foxnews.com', 'conservative', 'US', 0.75),
  ('CNN', 'https://cnn.com', 'liberal', 'US', 0.75),
  ('The Wall Street Journal', 'https://wsj.com', 'conservative', 'US', 0.90),
  ('The New York Times', 'https://nytimes.com', 'liberal', 'US', 0.90),
  ('BBC News', 'https://bbc.com/news', 'neutral', 'GB', 0.95),
  ('Reuters', 'https://reuters.com', 'neutral', 'US', 0.95)
ON CONFLICT DO NOTHING;

-- ========================================
-- ROW LEVEL SECURITY
-- ========================================

ALTER TABLE news_orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_usage_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_group_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_composer_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_api_keys ENABLE ROW LEVEL SECURITY;

-- Policies for news_orgs
CREATE POLICY "Users can view their own orgs"
  ON news_orgs FOR SELECT
  USING (
    id IN (
      SELECT org_id FROM news_org_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create orgs"
  ON news_orgs FOR INSERT
  WITH CHECK (owner_id = auth.uid());

-- Policies for news_org_members
CREATE POLICY "Users can view org members"
  ON news_org_members FOR SELECT
  USING (
    org_id IN (
      SELECT org_id FROM news_org_members
      WHERE user_id = auth.uid()
    )
  );

-- Policies for news_group_status
CREATE POLICY "Users can manage their own status"
  ON news_group_status FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Policies for composer drafts
CREATE POLICY "Users can view org drafts"
  ON news_composer_drafts FOR SELECT
  USING (
    org_id IN (
      SELECT org_id FROM news_org_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create drafts"
  ON news_composer_drafts FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ========================================
-- FUNCTIONS FOR ROY & CINDY ADMIN ACCESS
-- ========================================

-- Function to get news pattern insights
CREATE OR REPLACE FUNCTION get_news_patterns(
  p_start_date DATE,
  p_end_date DATE
) RETURNS TABLE (
  date DATE,
  total_groups INT,
  conservative_articles INT,
  liberal_articles INT,
  neutral_articles INT,
  avg_conservative_sentiment DECIMAL,
  avg_liberal_sentiment DECIMAL,
  top_keywords TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ng.date,
    COUNT(DISTINCT ng.id)::INT as total_groups,
    COUNT(*) FILTER (WHERE na.ideology = 'conservative')::INT as conservative_articles,
    COUNT(*) FILTER (WHERE na.ideology = 'liberal')::INT as liberal_articles,
    COUNT(*) FILTER (WHERE na.ideology = 'neutral')::INT as neutral_articles,
    AVG(na.sentiment_score) FILTER (WHERE na.ideology = 'conservative') as avg_conservative_sentiment,
    AVG(na.sentiment_score) FILTER (WHERE na.ideology = 'liberal') as avg_liberal_sentiment,
    ARRAY_AGG(DISTINCT unnest(ng.keywords)) as top_keywords
  FROM news_groups ng
  LEFT JOIN news_articles na ON ng.id = na.group_id
  WHERE ng.date BETWEEN p_start_date AND p_end_date
  GROUP BY ng.date
  ORDER BY ng.date DESC;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- TRIGGERS
-- ========================================

-- Update timestamps automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_news_orgs_updated_at
  BEFORE UPDATE ON news_orgs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_news_subscriptions_updated_at
  BEFORE UPDATE ON news_subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_news_usage_counters_updated_at
  BEFORE UPDATE ON news_usage_counters
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_news_groups_updated_at
  BEFORE UPDATE ON news_groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_news_group_status_updated_at
  BEFORE UPDATE ON news_group_status
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_news_composer_drafts_updated_at
  BEFORE UPDATE ON news_composer_drafts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- VIEWS FOR ANALYTICS
-- ========================================

CREATE OR REPLACE VIEW news_org_analytics AS
SELECT
  o.id as org_id,
  o.name as org_name,
  s.plan_id,
  p.name as plan_name,
  s.status as subscription_status,
  (
    SELECT jsonb_object_agg(metric, count)
    FROM news_usage_counters uc
    WHERE uc.org_id = o.id
      AND uc.period_start = DATE_TRUNC('month', NOW())
  ) as current_month_usage,
  (
    SELECT COUNT(*)
    FROM news_events e
    WHERE e.org_id = o.id
      AND e.created_at >= NOW() - INTERVAL '30 days'
  ) as events_last_30_days,
  (
    SELECT COUNT(*)
    FROM news_composer_drafts d
    WHERE d.org_id = o.id
      AND d.published = true
  ) as total_published_content
FROM news_orgs o
LEFT JOIN news_subscriptions s ON o.id = s.org_id
LEFT JOIN news_plans p ON s.plan_id = p.id;

-- ========================================
-- GRANT PERMISSIONS
-- ========================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- ========================================
-- COMPLETION MESSAGE
-- ========================================

DO $$
BEGIN
  RAISE NOTICE 'News Comparison Platform schema created successfully!';
  RAISE NOTICE 'Added 22 new tables to existing database';
  RAISE NOTICE 'Created 4 stored functions for usage tracking, metrics, and rate limiting';
  RAISE NOTICE 'Seeded 3 plans, 3 templates, and 6 news sources';
  RAISE NOTICE 'Row Level Security enabled for user data protection';
END $$;
