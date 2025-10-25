# ⚡ 2-MINUTE SCHEMA FIX - COPY & PASTE

**You're literally 2 minutes from a working app!**

---

## STEP 1: Open Supabase (10 seconds)

Click this link:
```
https://supabase.com/dashboard/project/kteobfyferrukqeolofj/sql
```

---

## STEP 2: Create New Query (5 seconds)

Click the **"+ New query"** button (top right)

---

## STEP 3: Copy Schema (10 seconds)

Open this link in a new tab:
```
https://raw.githubusercontent.com/CR-AudioViz-AI/crav-news-compare/main/database/schema.sql
```

Press **Ctrl+A** (select all) then **Ctrl+C** (copy)

---

## STEP 4: Paste & Run (10 seconds)

1. Go back to Supabase SQL Editor
2. Click in the query box
3. Press **Ctrl+V** (paste)
4. Click **"Run"** button (bottom right)
5. Wait ~30 seconds

---

## STEP 5: Verify (15 seconds)

Create a new query and run this:

```sql
SELECT COUNT(*) FROM pg_tables WHERE tablename LIKE 'news_%';
```

**Expected result:** `22`

If you see `22`, YOU'RE DONE! ✅

---

## STEP 6: Test Your App (30 seconds)

Visit:
```
https://crav-news-compare-quvy77mmj-roy-hendersons-projects-1d3d5e94.vercel.app/api/health
```

**Expected:** `{"status":"ok"}`

Visit:
```
https://crav-news-compare-quvy77mmj-roy-hendersons-projects-1d3d5e94.vercel.app/api/plans
```

**Expected:** JSON with 3 plans (free, pro, enterprise)

---

## 🎉 DONE!

Your news comparison platform is now **100% FUNCTIONAL**!

Next steps:
1. Create Stripe products (10 min) - QUICK_ACTIONS.md
2. Test features (15 min)
3. Embed in dashboard (10 min)

---

**Total Time:** 2 minutes + 30 seconds verification = **2.5 minutes** ⚡

**You got this!** 💪
