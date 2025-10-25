# CRAV News Comparison Platform

**Conservative vs Liberal news comparison with international reporting, JavariAI integration, and embeddable dashboard.**

**Part of the CR AudioViz AI ecosystem** - Integrates with your existing Supabase database, Stripe payments, and admin dashboard.

---

## 🚀 Quick Start

### Prerequisites

- Node.js 20+ 
- npm 10+ or pnpm 9+
- Supabase account (already configured)
- Stripe account (already configured)
- Vercel account (for deployment)

### Installation

```bash
# Clone repository
git clone https://github.com/CR-AudioViz-AI/crav-news-compare.git
cd crav-news-compare

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env.local
# Edit .env.local with your credentials (already pre-filled)

# Apply database schema
npm run db:push

# Start development server
npm run dev
```

Visit `http://localhost:3000` to see the app.

---

## 🏗️ Architecture

### Tech Stack

- **Frontend**: Next.js 14 (App Router), React 18, TypeScript
- **Styling**: Tailwind CSS, shadcn/ui components
- **Database**: Supabase (PostgreSQL)
- **Payments**: Stripe + PayPal
- **Analytics**: Custom telemetry + OpenTelemetry
- **Hosting**: Vercel (preview-only deployments)

### Database Schema

Adds **22 new tables** to your existing 33-table Supabase database:

- Organizations & memberships
- Plans & subscriptions
- Usage tracking & quotas
- News sources, groups, articles
- User interactions (save/archive)
- Composer drafts & templates
- Shortlinks & analytics
- Rate limiting
- API keys
- Coupons & referrals

### Key Features

1. **Dual-Column News Comparison**
   - Conservative vs Liberal article display
   - Saved/archived filtering
   - Real-time telemetry tracking

2. **International Reporting**
   - Multi-country news lanes
   - Paywalled by quota
   - Keyword filtering

3. **Diff Tool**
   - Sentence-level article comparison
   - Highlights left-only/right-only content
   - Similarity scoring

4. **Composer Pro**
   - AI-powered content generation
   - Newsletter, social, email templates
   - Shortlink creation
   - Schedule/publish workflows

5. **Analytics Dashboard**
   - Event tracking & funnels
   - Source performance metrics
   - Guardrails & abuse detection

6. **Billing & Subscriptions**
   - Free, Pro, Enterprise plans
   - Stripe checkout integration
   - Usage quota enforcement

7. **Public API**
   - OpenAPI specification
   - TypeScript & React Native SDKs
   - Rate limiting
   - API key management

8. **JavariAI Integration**
   - `/api/javari/news-feed` - Structured data export
   - `/api/javari/patterns` - Bias pattern detection
   - `/api/javari/trending` - Trending topics analysis

9. **Embeddable Mode**
   - Card mode (300px height) for dashboard
   - Full dashboard mode when expanded
   - PostMessage API for parent communication

---

## 📁 Project Structure

```
crav-news-compare/
├── src/
│   ├── app/                 # Next.js App Router pages
│   │   ├── compare/         # Main comparison view
│   │   ├── international/   # Multi-country view
│   │   ├── diff/            # Article diff tool
│   │   ├── composer/        # Content composer
│   │   ├── analytics/       # Analytics dashboard
│   │   ├── billing/         # Subscription management
│   │   ├── developers/      # API docs & SDKs
│   │   └── api/             # API routes (15+ endpoints)
│   ├── components/          # React components
│   │   ├── ui/              # shadcn/ui components
│   │   ├── layout/          # Layout components
│   │   ├── news/            # News-specific components
│   │   └── composer/        # Composer components
│   ├── lib/                 # Utilities
│   │   ├── supabase.ts      # Database client
│   │   ├── stripe.ts        # Payment processing
│   │   ├── telemetry.ts     # Analytics tracking
│   │   └── utils.ts         # Helper functions
│   └── types/               # TypeScript types
├── supabase/                # Database schema
│   └── schema.sql           # Complete schema with seeds
├── public/                  # Static assets
│   └── sdk/                 # TypeScript & RN SDKs
├── tests/                   # Vitest tests
├── vercel.json              # Vercel config (preview-only)
├── next.config.js           # Next.js config
├── tailwind.config.ts       # Tailwind config
└── package.json             # Dependencies
```

---

## 🔐 Environment Variables

### Required Variables (Pre-filled from Master Credentials)

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://kteobfyferrukqeolofj.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Stripe
STRIPE_SECRET_KEY=EBT...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live...
BILLING_WEBHOOK_SECRET=whsec_...

# OpenAI (JavariAI)
OPENAI_API_KEY=sk-proj-...

# Feature Flags
NEXT_PUBLIC_ANALYTICS_ENABLED=true
NEXT_PUBLIC_AB_TESTS_ENABLED=true

# URLs
NEXT_PUBLIC_ADMIN_DOMAIN=https://craudiovizai.com
NEXT_PUBLIC_JAVARI_API=https://javariai.com/api
```

### Stripe Product IDs (Create in Stripe Dashboard)

After creating products in Stripe, update these:

```env
STRIPE_PRICE_FREE=price_xxx
STRIPE_PRICE_PRO=price_xxx
STRIPE_PRICE_ENTERPRISE=price_xxx
```

---

## 🚀 Deployment

### Vercel Setup (Preview-Only Mode)

1. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "feat: initial CRAV news comparison platform"
   git push origin main
   ```

2. **Create Vercel Project:**
   - Import from GitHub: `CR-AudioViz-AI/crav-news-compare`
   - Framework: Next.js
   - Root Directory: `./`
   - Build Command: `npm run build`

3. **Add Environment Variables:**
   - Copy all variables from `.env.local` to Vercel project settings
   - Set for both Production and Preview environments

4. **Configure Preview-Only Deployments:**
   - The `vercel.json` file automatically configures preview-only mode
   - Every push creates a **preview deployment**
   - **Manual promotion required** for production (saves credits!)

5. **Set Stripe Webhook:**
   - After first deploy, copy your Vercel URL
   - In Stripe Dashboard: Webhooks → Add endpoint
   - URL: `https://your-app.vercel.app/api/billing/webhook`
   - Events: `checkout.session.completed`, `customer.subscription.*`, `invoice.*`
   - Copy webhook secret to `BILLING_WEBHOOK_SECRET` in Vercel

### Preview Deployment Workflow

```
Git Push → Vercel Preview Deploy → Manual Test → Promote to Production
```

**Cost Savings:** Only production promotions consume significant credits.

---

## 🧪 Testing

```bash
# Run tests
npm test

# Run with coverage
npm run test:coverage

# Type check
npm run type-check

# Lint
npm run lint
```

---

## 📊 Monitoring & Analytics

### Built-in Telemetry

All user interactions automatically tracked:
- Page views
- Article impressions/clicks
- Save/archive actions
- Composer usage
- Checkout flows

### Access Analytics

- **User Dashboard**: `/analytics`
- **Source Analytics**: `/analytics/sources`
- **Guardrails**: `/analytics/guardrails`

### JavariAI Integration

```typescript
// Example: Get news patterns for JavariAI
GET /api/javari/patterns?start_date=2025-10-01&end_date=2025-10-25

// Response:
{
  "patterns": [
    {
      "pattern_type": "bias",
      "description": "Conservative sources emphasize X, liberal sources emphasize Y",
      "confidence": 0.87,
      "evidence": { ... }
    }
  ]
}
```

---

## 🔗 Embedding in Admin Dashboard

### Card Mode (Compact)

```html
<iframe 
  src="https://your-app.vercel.app?embedded=true"
  width="100%"
  height="300px"
  frameborder="0"
></iframe>
```

### Dashboard Mode (Full)

```html
<iframe 
  src="https://your-app.vercel.app?embedded=true&mode=dashboard"
  width="100%"
  height="100vh"
  frameborder="0"
></iframe>
```

### PostMessage API

```javascript
// Expand to dashboard mode
iframe.contentWindow.postMessage({
  source: 'crav-admin',
  type: 'expand',
  payload: {}
}, '*');

// Listen for events from embedded app
window.addEventListener('message', (event) => {
  if (event.data.source === 'crav-news-compare') {
    console.log('Event:', event.data.type, event.data.payload);
  }
});
```

---

## 🛠️ Development Commands

```bash
# Start dev server
npm run dev

# Build for production
npm run build

# Start production server
npm run start

# Run database migrations
npm run db:push

# Reset database
npm run db:reset

# Format code
npm run format

# Type check
npm run type-check
```

---

## 📚 API Documentation

### Core Endpoints

```
GET  /api/compare                    # Get news groups
GET  /api/compare/countries          # International lanes
GET  /api/groups/status              # User saved/archived status
POST /api/groups/:id/save            # Save group
POST /api/groups/:id/archive         # Archive group
GET  /api/groups/:id/diff            # Sentence diff
POST /api/compose                    # Generate content
POST /api/compose/publish            # Publish content
POST /api/shortlinks                 # Create shortlink
GET  /api/slug/[code]                # Redirect shortlink
POST /api/telemetry/track            # Track event
GET  /api/analytics/summary          # Get analytics
GET  /api/analytics/sources          # Source metrics
POST /api/billing/checkout           # Create checkout
POST /api/billing/webhook            # Stripe webhook
GET  /api/keys                       # List API keys
POST /api/keys                       # Create API key
DELETE /api/keys/:id                 # Revoke API key
```

### JavariAI Endpoints

```
GET  /api/javari/news-feed           # Structured news data
GET  /api/javari/patterns            # Bias patterns
GET  /api/javari/trending            # Trending topics
```

### Public API (Rate Limited)

```
GET  /api/public/groups              # Public news groups
GET  /api/public/diff                # Public diff tool
```

---

## 🤝 Integration with CR AudioViz AI Ecosystem

### Shared Resources

- **Supabase Database**: Adds tables to existing schema
- **Stripe Account**: Uses existing payment setup
- **Admin Dashboard**: Embeds as expandable card
- **JavariAI**: Feeds data for learning & analysis

### For Roy & Cindy

**Admin Learning Dashboard**: Access at `/analytics/patterns`

Provides:
- News bias pattern detection
- Source reliability metrics
- Trending topic analysis
- Sentiment tracking
- Coverage comparison

Perfect for studying media patterns and training JavariAI!

---

## 📝 License

Proprietary - CR AudioViz AI, LLC

---

## 📧 Support

- **Email**: info@craudiovizai.com
- **Website**: https://craudiovizai.com
- **Vercel Dashboard**: https://vercel.com/dashboard

---

**Built with ❤️ by Claude for Roy Henderson & CR AudioViz AI**
