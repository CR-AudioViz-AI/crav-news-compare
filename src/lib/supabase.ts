// CR AudioViz AI - Supabase Client Configuration
// Provides both server-side and client-side Supabase clients

import { createClient } from '@supabase/supabase-js';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { Database } from '@/types/database.types';

// ========================================
// ENVIRONMENT VARIABLES
// ========================================

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

// ========================================
// CLIENT-SIDE SUPABASE CLIENT
// ========================================

export const createBrowserClient = () => {
  return createClient<Database>(supabaseUrl, supabaseAnonKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
    },
  });
};

// ========================================
// SERVER-SIDE SUPABASE CLIENT
// ========================================

export const createServerSupabaseClient = async () => {
  const cookieStore = await cookies();

  return createServerClient<Database>(supabaseUrl, supabaseAnonKey, {
    cookies: {
      get(name: string) {
        return cookieStore.get(name)?.value;
      },
      set(name: string, value: string, options: any) {
        try {
          cookieStore.set({ name, value, ...options });
        } catch (error) {
          // Handle cookie setting errors (e.g., in middleware)
        }
      },
      remove(name: string, options: any) {
        try {
          cookieStore.set({ name, value: '', ...options });
        } catch (error) {
          // Handle cookie removal errors
        }
      },
    },
  });
};

// ========================================
// SERVICE ROLE CLIENT (ADMIN OPERATIONS)
// ========================================

export const createServiceRoleClient = () => {
  if (!supabaseServiceRoleKey) {
    throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY');
  }

  return createClient<Database>(supabaseUrl, supabaseServiceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
};

// ========================================
// HELPER FUNCTIONS
// ========================================

/**
 * Get the current authenticated user
 */
export async function getCurrentUser() {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error) {
    console.error('Error getting current user:', error);
    return null;
  }

  return user;
}

/**
 * Get the user's organization
 */
export async function getUserOrg(userId: string) {
  const supabase = await createServerSupabaseClient();

  const { data, error } = await supabase
    .from('news_org_members')
    .select('org_id, role, news_orgs(*)')
    .eq('user_id', userId)
    .single();

  if (error) {
    console.error('Error getting user org:', error);
    return null;
  }

  return data;
}

/**
 * Get organization's current subscription and plan
 */
export async function getOrgSubscription(orgId: string) {
  const supabase = await createServerSupabaseClient();

  const { data, error } = await supabase
    .from('news_subscriptions')
    .select('*, news_plans(*)')
    .eq('org_id', orgId)
    .eq('status', 'active')
    .single();

  if (error) {
    console.error('Error getting org subscription:', error);
    // Return free plan as default
    const { data: freePlan } = await supabase
      .from('news_plans')
      .select('*')
      .eq('id', 'free')
      .single();

    return {
      plan: freePlan,
      subscription: null,
    };
  }

  return {
    plan: data.news_plans,
    subscription: data,
  };
}

/**
 * Check if organization has access to a feature
 */
export async function checkFeatureAccess(
  orgId: string,
  feature: string
): Promise<boolean> {
  const { plan } = await getOrgSubscription(orgId);

  if (!plan || !plan.features) {
    return false;
  }

  const features = plan.features as Record<string, boolean>;
  return features[feature] === true;
}

/**
 * Check and consume quota for a metric
 */
export async function checkAndConsumeQuota(
  orgId: string,
  metric: string,
  amount: number = 1
): Promise<{ allowed: boolean; current: number; limit: number }> {
  const supabase = createServiceRoleClient();

  // Get current subscription and plan
  const { plan } = await getOrgSubscription(orgId);

  if (!plan || !plan.monthly_quota) {
    return { allowed: false, current: 0, limit: 0 };
  }

  const quotas = plan.monthly_quota as Record<string, number>;
  const limit = quotas[metric] || 0;

  // -1 means unlimited
  if (limit === -1) {
    await supabase.rpc('bump_news_usage', {
      p_org: orgId,
      p_metric: metric,
      p_inc: amount,
    });
    return { allowed: true, current: 0, limit: -1 };
  }

  // Get current usage
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);

  const { data: usage } = await supabase
    .from('news_usage_counters')
    .select('count')
    .eq('org_id', orgId)
    .eq('metric', metric)
    .gte('period_start', startOfMonth.toISOString())
    .single();

  const current = usage?.count || 0;

  if (current + amount > limit) {
    return { allowed: false, current, limit };
  }

  // Consume quota
  const { data: newCount } = await supabase.rpc('bump_news_usage', {
    p_org: orgId,
    p_metric: metric,
    p_inc: amount,
  });

  return { allowed: true, current: newCount || current, limit };
}

/**
 * Check rate limit
 */
export async function checkRateLimit(
  key: string,
  bucket: string,
  limit: number,
  windowSeconds: number = 60
): Promise<{ allowed: boolean; current: number; limit: number }> {
  const supabase = createServiceRoleClient();

  const { data: count } = await supabase.rpc('bump_news_rate', {
    p_key: key,
    p_bucket: bucket,
    p_inc: 1,
    p_window_secs: windowSeconds,
  });

  const current = count || 0;
  const allowed = current <= limit;

  return { allowed, current, limit };
}
