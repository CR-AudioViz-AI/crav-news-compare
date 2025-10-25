# ⚡ QUICK ACTION CHECKLIST - News Platform Launch

**Time Estimate: 45 minutes total**  
**Priority: Complete in order for fastest launch**

---

## ☑️ ACTION 1: Apply Database Schema (5 min) ⚠️ CRITICAL

**Must complete first - everything else depends on this!**

### Steps:
1. Open: https://supabase.com/dashboard/project/kteobfyferrukqeolofj/sql
2. Click: "+ New query"
3. Copy ALL text from: https://github.com/CR-AudioViz-AI/crav-news-compare/blob/main/database/schema.sql
4. Paste into SQL editor
5. Click: "Run" (bottom right)
6. Wait ~30 seconds for completion

### Verify Success:
Run this query in a new tab:
```sql
SELECT COUNT(*) as table_count 
FROM pg_tables 
WHERE tablename LIKE 'news_%';
```
**Expected Result:** 22

### If Error Occurs:
- Check for timeout → Split schema into 3 parts, run separately
- See line number → Fix syntax at that line
- Permission error → Use service_role key

**Status:** [ ] Complete ✅

---

## ☑️ ACTION 2: Create Stripe Products (10 min)

### Pro Plan
1. Go to: https://dashboard.stripe.com/products
2. Click: "+ Add product"
3. Fill in:
   - **Name:** CRAV News Pro
   - **Description:** Professional news comparison with API access, international sources, and AI composer
   - **Pricing:** $29.00 USD
   - **Billing period:** Monthly
4. Click "Save product"
5. **Copy Price ID** (starts with `price_`) → Save to notes

### Enterprise Plan
1. Click: "+ Add product" again
2. Fill in:
   - **Name:** CRAV News Enterprise
   - **Description:** Unlimited access for organizations with white-label options and priority support
   - **Pricing:** $99.00 USD
   - **Billing period:** Monthly
3. Click "Save product"
4. **Copy Price ID** (starts with `price_`) → Save to notes

### Update Database
Open Supabase SQL Editor and run:
```sql
UPDATE news_plans 
SET stripe_price_id = 'price_YOUR_PRO_ID_HERE' 
WHERE id = 'pro';

UPDATE news_plans 
SET stripe_price_id = 'price_YOUR_ENTERPRISE_ID_HERE' 
WHERE id = 'enterprise';

-- Verify
SELECT id, name, stripe_price_id, price_monthly 
FROM news_plans;
```

**Status:** [ ] Complete ✅

---

## ☑️ ACTION 3: Configure Stripe Webhook (5 min)

### Setup Webhook
1. Go to: https://dashboard.stripe.com/webhooks
2. Click: "+ Add endpoint"
3. **Endpoint URL:** 
   ```
   https://crav-news-compare-quvy77mmj-roy-hendersons-projects-1d3d5e94.vercel.app/api/webhooks/stripe
   ```
4. Click: "Select events"
5. Select these 6 events:
   - ✅ checkout.session.completed
   - ✅ customer.subscription.created
   - ✅ customer.subscription.updated
   - ✅ customer.subscription.deleted
   - ✅ invoice.payment_succeeded
   - ✅ invoice.payment_failed
6. Click: "Add events" then "Add endpoint"
7. **Copy Signing Secret** (starts with `whsec_`)

### Update Vercel
1. Go to: https://vercel.com/roy-hendersons-projects-1d3d5e94/crav-news-compare/settings/environment-variables
2. Find: `STRIPE_WEBHOOK_SECRET`
3. Click "Edit" 
4. Paste your new webhook secret
5. Save changes
6. Redeploy if needed

**Status:** [ ] Complete ✅

---

## ☑️ ACTION 4: Test Application (15 min)

### Basic Tests
Open these URLs in your browser:

1. **Homepage**
   ```
   https://crav-news-compare-quvy77mmj-roy-hendersons-projects-1d3d5e94.vercel.app
   ```
   Expected: Landing page loads

2. **Health Check**
   ```
   https://crav-news-compare-quvy77mmj-roy-hendersons-projects-1d3d5e94.vercel.app/api/health
   ```
   Expected: `{"status":"ok"}`

3. **Plans API**
   ```
   https://crav-news-compare-quvy77mmj-roy-hendersons-projects-1d3d5e94.vercel.app/api/plans
   ```
   Expected: JSON array with 3 plans

4. **Auth Test**
   ```
   https://crav-news-compare-quvy77mmj-roy-hendersons-projects-1d3d5e94.vercel.app/auth/login
   ```
   Expected: Login form

### Feature Tests (after login)
- [ ] Save an article
- [ ] Create a comparison
- [ ] Access billing page
- [ ] View analytics

**Status:** [ ] Complete ✅

---

## ☑️ ACTION 5: Embed in Dashboard (10 min)

### Add to Main Admin Dashboard

1. Open: `craudiovizai-website` repo
2. File: `src/app/admin/page.tsx` (or your dashboard file)
3. Add import:
   ```tsx
   import { NewsCompareEmbed } from '@/components/embeds/NewsCompareEmbed';
   ```
4. Add to your dashboard grid:
   ```tsx
   <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
     {/* Your other cards */}
     <NewsCompareEmbed showControls={true} />
   </div>
   ```
5. Commit and push changes
6. Verify in live dashboard

**Status:** [ ] Complete ✅

---

## 📊 COMPLETION TRACKER

**Overall Progress:**
- [ ] Database (5 min)
- [ ] Stripe Products (10 min)
- [ ] Webhook (5 min)
- [ ] Testing (15 min)
- [ ] Embed (10 min)

**Total: ___ / 45 minutes**

---

## 🚨 TROUBLESHOOTING

### Database Errors
**Problem:** Query timeout  
**Solution:** Run schema in 3 parts:
1. Tables only (lines 1-500)
2. Functions & policies (lines 501-800)
3. Triggers & grants (lines 801-end)

### Stripe Issues
**Problem:** Products not showing  
**Solution:** Refresh page, check test vs live mode

### Webhook Fails
**Problem:** Webhook not receiving events  
**Solution:** 
- Verify URL is correct
- Check Vercel logs for errors
- Test with Stripe CLI: `stripe listen --forward-to localhost:3000/api/webhooks/stripe`

### App Not Loading
**Problem:** 404 or 401 errors  
**Solution:**
- Verify database applied
- Check Vercel environment variables
- View deployment logs

---

## ✅ DONE? WHAT'S NEXT?

Once all 5 actions complete:

1. **Populate News Sources**
   - Add conservative outlets (Fox, Breitbart, Daily Wire, etc.)
   - Add liberal outlets (CNN, MSNBC, HuffPost, etc.)
   - Add neutral outlets (Reuters, AP, BBC)

2. **Set Up Cron Jobs**
   - Vercel cron for hourly article fetching
   - Daily analytics aggregation
   - Weekly cleanup of old data

3. **JavariAI Integration**
   - Point JavariAI to `/api/javari/news-feed`
   - Train on bias pattern detection
   - Enable learning from user comparisons

4. **Beta Testing**
   - Invite 10 trusted users
   - Collect feedback
   - Monitor telemetry
   - Fix critical bugs

5. **Launch! 🚀**
   - Announce on social media
   - Submit to Product Hunt
   - Email your list
   - Press outreach

---

**You got this, partner! 💪**

**Your success is my success.** 🎉

---

*Quick Reference: Saturday, October 25, 2025 - 9:15 PM EST*
