// CR AudioViz AI - News Comparison Platform Types
// Generated: 2025-10-25 12:51:30 ET

import { Database } from './database.types';

// ========================================
// DATABASE TYPES
// ========================================

export type NewsOrg = Database['public']['Tables']['news_orgs']['Row'];
export type NewsOrgInsert = Database['public']['Tables']['news_orgs']['Insert'];
export type NewsOrgUpdate = Database['public']['Tables']['news_orgs']['Update'];

export type NewsOrgMember = Database['public']['Tables']['news_org_members']['Row'];
export type MemberRole = 'owner' | 'admin' | 'editor' | 'viewer';

export type NewsPlan = Database['public']['Tables']['news_plans']['Row'];
export type NewsSubscription = Database['public']['Tables']['news_subscriptions']['Row'];
export type SubscriptionStatus = 'active' | 'canceled' | 'past_due' | 'trialing' | 'incomplete';

export type NewsSource = Database['public']['Tables']['news_sources']['Row'];
export type Ideology = 'conservative' | 'liberal' | 'neutral' | 'mixed';

export type NewsGroup = Database['public']['Tables']['news_groups']['Row'];
export type NewsArticle = Database['public']['Tables']['news_articles']['Row'];
export type NewsGroupStatus = Database['public']['Tables']['news_group_status']['Row'];

export type ComposerDraft = Database['public']['Tables']['news_composer_drafts']['Row'];
export type ComposerTemplate = Database['public']['Tables']['news_composer_templates']['Row'];
export type ContentType = 'newsletter' | 'social' | 'email';

export type Shortlink = Database['public']['Tables']['news_shortlinks']['Row'];
export type TelemetryEvent = Database['public']['Tables']['news_events']['Row'];
export type SourceMetric = Database['public']['Tables']['news_source_metrics_daily']['Row'];

export type APIKey = Database['public']['Tables']['news_api_keys']['Row'];
export type Coupon = Database['public']['Tables']['news_coupons']['Row'];
export type Referral = Database['public']['Tables']['news_referrals']['Row'];

// ========================================
// API RESPONSE TYPES
// ========================================

export interface CompareResponse {
  date: string;
  groups: NewsGroupWithArticles[];
  summary: {
    total_groups: number;
    conservative_count: number;
    liberal_count: number;
    neutral_count: number;
  };
}

export interface NewsGroupWithArticles extends NewsGroup {
  conservative_articles: NewsArticleWithSource[];
  liberal_articles: NewsArticleWithSource[];
  neutral_articles: NewsArticleWithSource[];
  status?: NewsGroupStatus;
}

export interface NewsArticleWithSource extends NewsArticle {
  source: NewsSource;
}

export interface InternationalCompareResponse {
  country_code: string;
  country_name: string;
  groups: NewsGroupWithArticles[];
}

export interface DiffResponse {
  group_id: string;
  left_article: NewsArticle;
  right_article: NewsArticle;
  differences: {
    left_only: DiffSentence[];
    right_only: DiffSentence[];
    common: DiffSentence[];
  };
  similarity_score: number;
}

export interface DiffSentence {
  text: string;
  start_index: number;
  end_index: number;
}

export interface ComposerGenerateRequest {
  type: ContentType;
  template_id?: string;
  group_ids?: string[];
  custom_prompt?: string;
  variables?: Record<string, string>;
}

export interface ComposerPublishRequest {
  draft_id: string;
  channels: ('email' | 'social' | 'newsletter')[];
  schedule_at?: string;
}

export interface ShortlinkCreateRequest {
  target_url: string;
  title?: string;
  custom_code?: string;
}

export interface TelemetryTrackRequest {
  event_name: string;
  properties?: Record<string, any>;
  session_id: string;
}

export interface AnalyticsSummaryResponse {
  total_events: number;
  unique_users: number;
  top_events: Array<{
    event_name: string;
    count: number;
  }>;
  funnel: {
    saves: number;
    generates: number;
    publishes: number;
    conversion_rate: number;
  };
}

export interface SourceAnalyticsResponse {
  sources: Array<{
    source: NewsSource;
    impressions: number;
    clicks: number;
    ctr: number;
    avg_dwell_seconds: number;
  }>;
  by_ideology: Record<Ideology, {
    impressions: number;
    clicks: number;
    ctr: number;
  }>;
  by_country: Record<string, {
    impressions: number;
    clicks: number;
    ctr: number;
  }>;
}

export interface GuardrailsResponse {
  alerts: Array<{
    metric: string;
    current_value: number;
    previous_value: number;
    change_percent: number;
    severity: 'low' | 'medium' | 'high';
  }>;
}

export interface AbuseResponse {
  flagged_sessions: Array<{
    session_id: string;
    event_count: number;
    user_id?: string;
    first_seen: string;
    last_seen: string;
  }>;
}

// ========================================
// BILLING & CHECKOUT TYPES
// ========================================

export interface CheckoutRequest {
  plan_id: string;
  coupon_code?: string;
  success_url?: string;
  cancel_url?: string;
}

export interface CheckoutResponse {
  session_id: string;
  url: string;
}

export interface StripeWebhookEvent {
  id: string;
  type: string;
  data: {
    object: any;
  };
}

// ========================================
// JAVARI AI INTEGRATION TYPES
// ========================================

export interface JavariNewsFeedItem {
  group_id: string;
  date: string;
  title: string;
  keywords: string[];
  articles: Array<{
    id: string;
    source_name: string;
    ideology: Ideology;
    title: string;
    url: string;
    excerpt: string;
    sentiment_score: number;
    published_at: string;
  }>;
}

export interface JavariPatternInsight {
  pattern_type: 'bias' | 'sentiment' | 'coverage' | 'timing';
  description: string;
  confidence: number;
  evidence: {
    group_ids: string[];
    date_range: [string, string];
    affected_sources: string[];
  };
  metadata: Record<string, any>;
}

export interface JavariTrendingTopic {
  keyword: string;
  frequency: number;
  ideologies: Record<Ideology, number>;
  sentiment_trend: Array<{
    date: string;
    avg_sentiment: number;
  }>;
  related_groups: string[];
}

// ========================================
// ADMIN LEARNING DASHBOARD TYPES
// ========================================

export interface AdminPatternAnalysis {
  date_range: [string, string];
  patterns: JavariPatternInsight[];
  source_reliability: Array<{
    source: NewsSource;
    reliability_score: number;
    consistency_score: number;
    bias_score: number;
  }>;
  trending_topics: JavariTrendingTopic[];
}

// ========================================
// EMBEDDED MODE TYPES
// ========================================

export interface EmbeddedConfig {
  mode: 'card' | 'dashboard';
  max_height?: string;
  show_header?: boolean;
  show_footer?: boolean;
  theme?: 'light' | 'dark' | 'auto';
  api_base_url?: string;
}

export interface EmbeddedMessage {
  type: 'expand' | 'collapse' | 'navigate' | 'telemetry';
  payload: any;
}

// ========================================
// UTILITY TYPES
// ========================================

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    per_page: number;
    total: number;
    has_next: boolean;
    has_prev: boolean;
  };
}

export interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: Record<string, any>;
  };
}

export interface SuccessResponse<T = void> {
  success: true;
  data?: T;
  message?: string;
}

// ========================================
// QUOTA & FEATURE CHECK TYPES
// ========================================

export interface QuotaCheck {
  allowed: boolean;
  current_usage: number;
  quota_limit: number;
  remaining: number;
  resets_at: string;
}

export interface FeatureAccess {
  enabled: boolean;
  reason?: string;
  upgrade_required?: boolean;
}
