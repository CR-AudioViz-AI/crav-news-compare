// CR AudioViz AI - Utility Functions
// Common helpers used throughout the application

import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { format, formatDistanceToNow } from 'date-fns';
import type { ErrorResponse, SuccessResponse } from '@/types';

// ========================================
// STYLING UTILITIES
// ========================================

/**
 * Merge Tailwind CSS classes with proper precedence
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// ========================================
// DATE & TIME UTILITIES
// ========================================

/**
 * Format date for display
 */
export function formatDate(date: string | Date, pattern: string = 'PPP'): string {
  return format(new Date(date), pattern);
}

/**
 * Format relative time (e.g., "2 hours ago")
 */
export function formatRelativeTime(date: string | Date): string {
  return formatDistanceToNow(new Date(date), { addSuffix: true });
}

/**
 * Get date string for API queries (YYYY-MM-DD)
 */
export function getDateString(date: Date = new Date()): string {
  return format(date, 'yyyy-MM-dd');
}

// ========================================
// API RESPONSE UTILITIES
// ========================================

/**
 * Create success response
 */
export function successResponse<T>(
  data?: T,
  message?: string,
  status: number = 200
): Response {
  const response: SuccessResponse<T> = {
    success: true,
    data,
    message,
  };

  return new Response(JSON.stringify(response), {
    status,
    headers: {
      'Content-Type': 'application/json',
    },
  });
}

/**
 * Create error response
 */
export function errorResponse(
  message: string,
  code: string = 'ERROR',
  details?: Record<string, any>,
  status: number = 400
): Response {
  const response: ErrorResponse = {
    error: {
      code,
      message,
      details,
    },
  };

  return new Response(JSON.stringify(response), {
    status,
    headers: {
      'Content-Type': 'application/json',
    },
  });
}

/**
 * Create unauthorized response
 */
export function unauthorizedResponse(message: string = 'Unauthorized'): Response {
  return errorResponse(message, 'UNAUTHORIZED', undefined, 401);
}

/**
 * Create forbidden response
 */
export function forbiddenResponse(message: string = 'Forbidden'): Response {
  return errorResponse(message, 'FORBIDDEN', undefined, 403);
}

/**
 * Create not found response
 */
export function notFoundResponse(resource: string = 'Resource'): Response {
  return errorResponse(`${resource} not found`, 'NOT_FOUND', undefined, 404);
}

/**
 * Create rate limit response
 */
export function rateLimitResponse(
  limit: number,
  windowSeconds: number = 60
): Response {
  return errorResponse(
    `Rate limit exceeded. Maximum ${limit} requests per ${windowSeconds} seconds.`,
    'RATE_LIMIT_EXCEEDED',
    { limit, windowSeconds },
    429
  );
}

/**
 * Create quota exceeded response
 */
export function quotaExceededResponse(
  metric: string,
  current: number,
  limit: number
): Response {
  return errorResponse(
    `Quota exceeded for ${metric}. Current: ${current}, Limit: ${limit}`,
    'QUOTA_EXCEEDED',
    { metric, current, limit },
    402
  );
}

// ========================================
// STRING UTILITIES
// ========================================

/**
 * Generate a random string
 */
export function generateRandomString(length: number = 16): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * Generate a slug from text
 */
export function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/**
 * Truncate text with ellipsis
 */
export function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength - 3) + '...';
}

// ========================================
// NUMBER UTILITIES
// ========================================

/**
 * Format number with commas
 */
export function formatNumber(num: number): string {
  return new Intl.NumberFormat('en-US').format(num);
}

/**
 * Format currency
 */
export function formatCurrency(
  amount: number,
  currency: string = 'USD'
): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
  }).format(amount);
}

/**
 * Format percentage
 */
export function formatPercentage(value: number, decimals: number = 1): string {
  return `${(value * 100).toFixed(decimals)}%`;
}

// ========================================
// URL UTILITIES
// ========================================

/**
 * Build URL with query parameters
 */
export function buildUrl(
  base: string,
  params: Record<string, string | number | boolean | undefined>
): string {
  const url = new URL(base);

  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined) {
      url.searchParams.append(key, String(value));
    }
  });

  return url.toString();
}

/**
 * Get base URL for the application
 */
export function getBaseUrl(): string {
  if (process.env.NEXT_PUBLIC_APP_URL) {
    return process.env.NEXT_PUBLIC_APP_URL;
  }

  if (process.env.VERCEL_URL) {
    return `https://${process.env.VERCEL_URL}`;
  }

  return 'http://localhost:3000';
}

// ========================================
// VALIDATION UTILITIES
// ========================================

/**
 * Validate email format
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validate URL format
 */
export function isValidUrl(url: string): boolean {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

/**
 * Sanitize HTML to prevent XSS
 */
export function sanitizeHtml(html: string): string {
  return html
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// ========================================
// ARRAY UTILITIES
// ========================================

/**
 * Group array items by key
 */
export function groupBy<T>(
  array: T[],
  keyFn: (item: T) => string
): Record<string, T[]> {
  return array.reduce((result, item) => {
    const key = keyFn(item);
    if (!result[key]) {
      result[key] = [];
    }
    result[key].push(item);
    return result;
  }, {} as Record<string, T[]>);
}

/**
 * Remove duplicates from array
 */
export function unique<T>(array: T[]): T[] {
  return Array.from(new Set(array));
}

/**
 * Chunk array into smaller arrays
 */
export function chunk<T>(array: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

// ========================================
// CRYPTOGRAPHY UTILITIES
// ========================================

/**
 * Hash string using SHA-256 (for API keys, etc.)
 */
export async function hashString(input: string): Promise<string> {
  if (typeof window !== 'undefined' && window.crypto) {
    // Browser environment
    const encoder = new TextEncoder();
    const data = encoder.encode(input);
    const hashBuffer = await window.crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
  } else {
    // Node.js environment
    const crypto = await import('crypto');
    return crypto.createHash('sha256').update(input).digest('hex');
  }
}

// ========================================
// SESSION UTILITIES
// ========================================

/**
 * Generate session ID
 */
export function generateSessionId(): string {
  return `session_${Date.now()}_${generateRandomString(12)}`;
}

// ========================================
// EMBEDDED MODE UTILITIES
// ========================================

/**
 * Check if app is running in embedded mode
 */
export function isEmbedded(): boolean {
  if (typeof window === 'undefined') return false;

  const params = new URLSearchParams(window.location.search);
  return params.get('embedded') === 'true';
}

/**
 * Post message to parent window (for embedded mode)
 */
export function postToParent(type: string, payload: any): void {
  if (typeof window !== 'undefined' && window.parent !== window) {
    window.parent.postMessage(
      {
        source: 'crav-news-compare',
        type,
        payload,
      },
      '*'
    );
  }
}
