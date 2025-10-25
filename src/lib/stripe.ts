// CR AudioViz AI - Stripe Client Configuration
// Handles payment processing and webhook verification

import Stripe from 'stripe';

const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
const webhookSecret = process.env.BILLING_WEBHOOK_SECRET;

if (!stripeSecretKey) {
  throw new Error('Missing STRIPE_SECRET_KEY environment variable');
}

// ========================================
// STRIPE CLIENT
// ========================================

export const stripe = new Stripe(stripeSecretKey, {
  apiVersion: '2025-02-24.acacia',
  typescript: true,
  appInfo: {
    name: 'CR AudioViz AI - News Compare',
    version: '1.0.0',
    url: 'https://craudiovizai.com',
  },
});

// ========================================
// CHECKOUT SESSION CREATION
// ========================================

export interface CreateCheckoutSessionParams {
  priceId: string;
  customerId?: string;
  customerEmail?: string;
  metadata?: Record<string, string>;
  successUrl: string;
  cancelUrl: string;
  couponCode?: string;
}

export async function createCheckoutSession(
  params: CreateCheckoutSessionParams
): Promise<Stripe.Checkout.Session> {
  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    payment_method_types: ['card'],
    line_items: [
      {
        price: params.priceId,
        quantity: 1,
      },
    ],
    customer: params.customerId,
    customer_email: params.customerEmail,
    metadata: params.metadata,
    success_url: params.successUrl,
    cancel_url: params.cancelUrl,
    allow_promotion_codes: true,
    billing_address_collection: 'auto',
    automatic_tax: {
      enabled: true,
    },
    discounts: params.couponCode
      ? [
          {
            coupon: params.couponCode,
          },
        ]
      : undefined,
  });

  return session;
}

// ========================================
// CUSTOMER MANAGEMENT
// ========================================

export async function createStripeCustomer(
  email: string,
  name?: string,
  metadata?: Record<string, string>
): Promise<Stripe.Customer> {
  return await stripe.customers.create({
    email,
    name,
    metadata,
  });
}

export async function getStripeCustomer(
  customerId: string
): Promise<Stripe.Customer | null> {
  try {
    const customer = await stripe.customers.retrieve(customerId);
    return customer.deleted ? null : customer;
  } catch (error) {
    console.error('Error retrieving Stripe customer:', error);
    return null;
  }
}

// ========================================
// SUBSCRIPTION MANAGEMENT
// ========================================

export async function getSubscription(
  subscriptionId: string
): Promise<Stripe.Subscription | null> {
  try {
    return await stripe.subscriptions.retrieve(subscriptionId);
  } catch (error) {
    console.error('Error retrieving subscription:', error);
    return null;
  }
}

export async function cancelSubscription(
  subscriptionId: string,
  cancelAtPeriodEnd: boolean = true
): Promise<Stripe.Subscription> {
  return await stripe.subscriptions.update(subscriptionId, {
    cancel_at_period_end: cancelAtPeriodEnd,
  });
}

export async function updateSubscription(
  subscriptionId: string,
  newPriceId: string
): Promise<Stripe.Subscription> {
  const subscription = await stripe.subscriptions.retrieve(subscriptionId);

  return await stripe.subscriptions.update(subscriptionId, {
    items: [
      {
        id: subscription.items.data[0].id,
        price: newPriceId,
      },
    ],
    proration_behavior: 'always_invoice',
  });
}

// ========================================
// WEBHOOK VERIFICATION
// ========================================

export function verifyWebhookSignature(
  payload: string | Buffer,
  signature: string
): Stripe.Event {
  if (!webhookSecret) {
    throw new Error('Missing BILLING_WEBHOOK_SECRET environment variable');
  }

  try {
    return stripe.webhooks.constructEvent(payload, signature, webhookSecret);
  } catch (error) {
    console.error('Webhook signature verification failed:', error);
    throw new Error('Invalid webhook signature');
  }
}

// ========================================
// WEBHOOK EVENT HANDLERS
// ========================================

export type WebhookHandler = (event: Stripe.Event) => Promise<void>;

export const webhookHandlers: Record<string, WebhookHandler> = {
  'checkout.session.completed': async (event: Stripe.Event) => {
    const session = event.data.object as Stripe.Checkout.Session;
    console.log('Checkout completed:', session.id);
    // Handler implementation in API route
  },

  'customer.subscription.created': async (event: Stripe.Event) => {
    const subscription = event.data.object as Stripe.Subscription;
    console.log('Subscription created:', subscription.id);
  },

  'customer.subscription.updated': async (event: Stripe.Event) => {
    const subscription = event.data.object as Stripe.Subscription;
    console.log('Subscription updated:', subscription.id);
  },

  'customer.subscription.deleted': async (event: Stripe.Event) => {
    const subscription = event.data.object as Stripe.Subscription;
    console.log('Subscription deleted:', subscription.id);
  },

  'invoice.paid': async (event: Stripe.Event) => {
    const invoice = event.data.object as Stripe.Invoice;
    console.log('Invoice paid:', invoice.id);
  },

  'invoice.payment_failed': async (event: Stripe.Event) => {
    const invoice = event.data.object as Stripe.Invoice;
    console.log('Invoice payment failed:', invoice.id);
  },
};

// ========================================
// PRICE UTILITIES
// ========================================

export async function getPrice(priceId: string): Promise<Stripe.Price | null> {
  try {
    return await stripe.prices.retrieve(priceId);
  } catch (error) {
    console.error('Error retrieving price:', error);
    return null;
  }
}

export async function listPrices(
  productId?: string
): Promise<Stripe.Price[]> {
  const prices = await stripe.prices.list({
    product: productId,
    active: true,
    expand: ['data.product'],
  });

  return prices.data;
}

// ========================================
// COUPON UTILITIES
// ========================================

export async function createCoupon(
  code: string,
  percentOff?: number,
  amountOff?: number,
  currency?: string
): Promise<Stripe.Coupon> {
  return await stripe.coupons.create({
    id: code,
    percent_off: percentOff,
    amount_off: amountOff,
    currency: currency || 'usd',
    duration: 'once',
  });
}

export async function getCoupon(code: string): Promise<Stripe.Coupon | null> {
  try {
    return await stripe.coupons.retrieve(code);
  } catch (error) {
    console.error('Error retrieving coupon:', error);
    return null;
  }
}

