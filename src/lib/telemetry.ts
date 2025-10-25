// CR AudioViz AI - Telemetry & Analytics Client
// Client-side event tracking that integrates with JavariAI

'use client';

import { generateSessionId } from './utils';

// ========================================
// TELEMETRY CLIENT
// ========================================

class TelemetryClient {
  private sessionId: string;
  private enabled: boolean;
  private apiBase: string;

  constructor() {
    this.sessionId = this.getOrCreateSessionId();
    this.enabled =
      process.env.NEXT_PUBLIC_ANALYTICS_ENABLED === 'true' &&
      typeof window !== 'undefined';
    this.apiBase = process.env.NEXT_PUBLIC_APP_URL || '';
  }

  /**
   * Get or create session ID from localStorage
   */
  private getOrCreateSessionId(): string {
    if (typeof window === 'undefined') {
      return generateSessionId();
    }

    let sessionId = localStorage.getItem('crav_session_id');

    if (!sessionId) {
      sessionId = generateSessionId();
      localStorage.setItem('crav_session_id', sessionId);
    }

    return sessionId;
  }

  /**
   * Track a custom event
   */
  async track(
    eventName: string,
    properties?: Record<string, any>
  ): Promise<void> {
    if (!this.enabled) return;

    try {
      await fetch(`${this.apiBase}/api/telemetry/track`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          session_id: this.sessionId,
          event_name: eventName,
          properties: {
            ...properties,
            timestamp: new Date().toISOString(),
            user_agent: navigator.userAgent,
            screen_width: window.innerWidth,
            screen_height: window.innerHeight,
          },
        }),
      });
    } catch (error) {
      console.error('Telemetry tracking error:', error);
    }
  }

  /**
   * Track a goal/conversion event
   */
  async goal(goalName: string, value?: number): Promise<void> {
    return this.track(`goal_${goalName}`, { value });
  }

  /**
   * Track page view
   */
  async pageView(path?: string): Promise<void> {
    const currentPath = path || window.location.pathname;
    return this.track('page_view', {
      path: currentPath,
      referrer: document.referrer,
    });
  }

  /**
   * Track article impression
   */
  async articleImpression(
    articleId: string,
    sourceId: string,
    ideology: string
  ): Promise<void> {
    return this.track('article_impression', {
      article_id: articleId,
      source_id: sourceId,
      ideology,
    });
  }

  /**
   * Track article click
   */
  async articleClick(
    articleId: string,
    sourceId: string,
    ideology: string,
    dwellSeconds?: number
  ): Promise<void> {
    return this.track('article_click', {
      article_id: articleId,
      source_id: sourceId,
      ideology,
      dwell_seconds: dwellSeconds,
    });
  }

  /**
   * Track group save
   */
  async groupSave(groupId: string): Promise<void> {
    return this.track('group_save', { group_id: groupId });
  }

  /**
   * Track group archive
   */
  async groupArchive(groupId: string): Promise<void> {
    return this.track('group_archive', { group_id: groupId });
  }

  /**
   * Track compose generation
   */
  async composeGenerate(type: string, templateId?: string): Promise<void> {
    return this.track('compose_generate', {
      type,
      template_id: templateId,
    });
  }

  /**
   * Track compose publish
   */
  async composePublish(
    draftId: string,
    channels: string[]
  ): Promise<void> {
    return this.track('compose_publish', {
      draft_id: draftId,
      channels,
    });
  }

  /**
   * Track international view
   */
  async internationalView(countryCodes: string[]): Promise<void> {
    return this.track('intl_compare_view', {
      country_codes: countryCodes,
    });
  }

  /**
   * Track diff view
   */
  async diffView(
    groupId: string,
    leftArticleId: string,
    rightArticleId: string
  ): Promise<void> {
    return this.track('diff_view', {
      group_id: groupId,
      left_article_id: leftArticleId,
      right_article_id: rightArticleId,
    });
  }

  /**
   * Track API key creation
   */
  async apiKeyCreate(): Promise<void> {
    return this.track('api_key_create');
  }

  /**
   * Track upgrade intent
   */
  async upgradeIntent(fromPlan: string, toPlan: string): Promise<void> {
    return this.track('upgrade_intent', {
      from_plan: fromPlan,
      to_plan: toPlan,
    });
  }

  /**
   * Track checkout started
   */
  async checkoutStarted(planId: string, price: number): Promise<void> {
    return this.track('checkout_started', {
      plan_id: planId,
      price,
    });
  }

  /**
   * Track checkout completed
   */
  async checkoutCompleted(
    planId: string,
    price: number,
    subscriptionId: string
  ): Promise<void> {
    return this.track('checkout_completed', {
      plan_id: planId,
      price,
      subscription_id: subscriptionId,
    });
  }

  /**
   * Track error
   */
  async error(errorName: string, errorMessage: string, stack?: string): Promise<void> {
    return this.track('error', {
      error_name: errorName,
      error_message: errorMessage,
      stack,
    });
  }
}

// ========================================
// SINGLETON INSTANCE
// ========================================

let telemetryInstance: TelemetryClient | null = null;

export function getTelemetry(): TelemetryClient {
  if (!telemetryInstance) {
    telemetryInstance = new TelemetryClient();
  }
  return telemetryInstance;
}

// ========================================
// CONVENIENCE EXPORTS
// ========================================

export const telemetry = {
  track: (eventName: string, properties?: Record<string, any>) =>
    getTelemetry().track(eventName, properties),
  goal: (goalName: string, value?: number) =>
    getTelemetry().goal(goalName, value),
  pageView: (path?: string) => getTelemetry().pageView(path),
  articleImpression: (articleId: string, sourceId: string, ideology: string) =>
    getTelemetry().articleImpression(articleId, sourceId, ideology),
  articleClick: (
    articleId: string,
    sourceId: string,
    ideology: string,
    dwellSeconds?: number
  ) => getTelemetry().articleClick(articleId, sourceId, ideology, dwellSeconds),
  groupSave: (groupId: string) => getTelemetry().groupSave(groupId),
  groupArchive: (groupId: string) => getTelemetry().groupArchive(groupId),
  composeGenerate: (type: string, templateId?: string) =>
    getTelemetry().composeGenerate(type, templateId),
  composePublish: (draftId: string, channels: string[]) =>
    getTelemetry().composePublish(draftId, channels),
  internationalView: (countryCodes: string[]) =>
    getTelemetry().internationalView(countryCodes),
  diffView: (groupId: string, leftArticleId: string, rightArticleId: string) =>
    getTelemetry().diffView(groupId, leftArticleId, rightArticleId),
  apiKeyCreate: () => getTelemetry().apiKeyCreate(),
  upgradeIntent: (fromPlan: string, toPlan: string) =>
    getTelemetry().upgradeIntent(fromPlan, toPlan),
  checkoutStarted: (planId: string, price: number) =>
    getTelemetry().checkoutStarted(planId, price),
  checkoutCompleted: (planId: string, price: number, subscriptionId: string) =>
    getTelemetry().checkoutCompleted(planId, price, subscriptionId),
  error: (errorName: string, errorMessage: string, stack?: string) =>
    getTelemetry().error(errorName, errorMessage, stack),
};

// ========================================
// REACT HOOK
// ========================================

export function useTelemetry() {
  return telemetry;
}
