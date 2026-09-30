# 🚀 VARSHA Deployment Checklist

Use this checklist before deploying to production.

---

## Pre-Deployment Checklist

### ✅ Repository Setup

- [ ] Code pushed to GitHub
- [ ] `.gitignore` properly configured
- [ ] `README.md` updated with deployment URLs
- [ ] All sensitive data removed from commits

### ✅ Backend (Render)

- [ ] `backend/requirements.txt` exists and is up-to-date
- [ ] `backend/Dockerfile` created
- [ ] `render.yaml` configured with correct paths
- [ ] Models directory exists (`backend/models/`)
- [ ] `varsha_models.joblib` file present (or pipeline can generate it)
- [ ] Export data generated (`frontend/public/data/`)
- [ ] Health check endpoint working locally: `http://localhost:8000/api/health`
- [ ] API docs accessible locally: `http://localhost:8000/docs`

### ✅ Frontend (Vercel)

- [ ] `frontend/package.json` has all dependencies
- [ ] `frontend/vercel.json` created
- [ ] `.env.production` created with backend URL
- [ ] Local build succeeds: `npm run build`
- [ ] Preview works: `npm run preview`
- [ ] All API endpoints tested locally

---

## Deployment Steps

### 1. Backend Deployment (Render)

```bash
# Step 1: Ensure models and data exist
cd backend
python run_pipeline.py

# Step 2: Test locally
python server.py
# Visit http://localhost:8000/api/health

# Step 3: Commit everything
cd ..
git add .
git commit -m "Prepare for deployment"
git push origin main

# Step 4: Deploy to Render
# → Go to https://dashboard.render.com/
# → New Blueprint
# → Connect GitHub repo
# → Deploy
```

**Expected Render Build Time:** 5-10 minutes

### 2. Frontend Deployment (Vercel)

```bash
# Step 1: Test build
cd frontend
npm run build
npm run preview

# Step 2: Update API URL in .env.production
# Replace with your actual Render URL:
echo "VITE_API_URL=https://your-backend.onrender.com" > .env.production

# Step 3: Deploy
vercel --prod

# Or use Vercel dashboard:
# → Import Git Repository
# → Select 'frontend' as root directory
# → Add environment variable: VITE_API_URL
# → Deploy
```

**Expected Vercel Build Time:** 2-3 minutes

---

## Post-Deployment Verification

### Backend Verification

```bash
# Health check
curl https://your-backend.onrender.com/api/health

# Expected response:
# {
#   "status": "ok",
#   "mode": "simulated",
#   "dates": ["2024-06-01", "2025-09-30"],
#   "districts": 726,
#   "regimes": ["active", "break", "depression", "coastal", "wd", "normal"]
# }

# Test metadata endpoint
curl https://your-backend.onrender.com/api/meta

# Test forecast endpoint
curl https://your-backend.onrender.com/api/forecast/2024-06-15?lead=1

# Check API documentation
open https://your-backend.onrender.com/docs
```

### Frontend Verification

```bash
# Open in browser
open https://your-app.vercel.app

# Check browser console for errors (F12)
# - No CORS errors
# - API calls succeed (200 OK)
# - No 404 errors for assets

# Test each page:
# 1. Console page - map loads, regime works
# 2. Districts page - warnings display, CSV downloads
# 3. Regime Lab page - classifier works
# 4. Verification page - metrics display
```

---

## Performance Checks

### Backend Performance

```bash
# Response time test
time curl https://your-backend.onrender.com/api/health

# Load test (optional, use Apache Bench)
ab -n 100 -c 10 https://your-backend.onrender.com/api/health
```

**Expected Response Time:**
- Health check: < 200ms (after warm-up)
- Forecast API: < 500ms
- First request (cold start on free tier): 30-60 seconds

### Frontend Performance

```bash
# Lighthouse audit
npm install -g lighthouse
lighthouse https://your-app.vercel.app --view
```

**Target Scores:**
- Performance: > 90
- Accessibility: > 95
- Best Practices: > 95
- SEO: > 90

---

## Common Issues & Quick Fixes

### ❌ Backend: "Application failed to respond"

**Diagnosis:**
```bash
# Check Render logs
# Render Dashboard → Your Service → Logs
```

**Common causes:**
1. Pipeline taking too long → Pre-train models and commit them
2. Out of memory → Upgrade to Starter plan
3. Missing dependencies → Check requirements.txt

**Quick fix:**
```bash
cd backend
python run_pipeline.py
git add models/ ../frontend/public/data/
git commit -m "Add pre-trained models"
git push
```

### ❌ Frontend: "API calls failing"

**Diagnosis:**
```bash
# Check browser console (F12)
# Look for CORS or 404 errors
```

**Common causes:**
1. Wrong API URL in environment variable
2. Backend not deployed yet
3. CORS configuration issue

**Quick fix:**
```bash
# Update .env.production
echo "VITE_API_URL=https://your-actual-backend.onrender.com" > frontend/.env.production

# Redeploy
cd frontend
vercel --prod
```

### ❌ Backend: "Module 'varsha' not found"

**Cause:** Python can't find the varsha package

**Quick fix:**
```bash
# Ensure backend directory structure is correct:
backend/
├── varsha/
│   ├── __init__.py
│   ├── config.py
│   └── ...
├── server.py
└── requirements.txt

# Check if __init__.py exists in varsha/
ls -la backend/varsha/__init__.py
```

### ❌ Frontend: "Failed to load data/meta.json"

**Cause:** Export data not generated

**Quick fix:**
```bash
cd backend
python run_pipeline.py

# Verify data exists
ls -la ../frontend/public/data/
```

---

## Monitoring Setup

### Backend Monitoring (Free)

1. **UptimeRobot** (https://uptimerobot.com)
   - Add HTTP(s) monitor
   - URL: `https://your-backend.onrender.com/api/health`
   - Check interval: 5 minutes
   - Alert: Email on downtime

2. **Render Dashboard**
   - Built-in metrics: CPU, Memory, Requests
   - View logs in real-time
   - Set up email alerts

### Frontend Monitoring

1. **Vercel Analytics** (Built-in, Free)
   - Enable in project settings
   - Track page views, performance

2. **Vercel Speed Insights**
   ```bash
   cd frontend
   npm install @vercel/speed-insights
   
   # Add to main.tsx
   import { SpeedInsights } from '@vercel/speed-insights/react';
   
   // In your app component
   <SpeedInsights />
   ```

---

## Rollback Plan

### If deployment fails:

#### Backend Rollback (Render)
1. Render Dashboard → Your Service
2. Click "Rollback" button
3. Select previous stable deployment
4. Confirm rollback

#### Frontend Rollback (Vercel)
```bash
# List recent deployments
vercel ls

# Promote previous deployment to production
vercel promote <deployment-url>

# Or via dashboard:
# Deployments → Select stable deployment → Promote to Production
```

---

## Final Production Readiness

### Before Going Live:

- [ ] Backend responds < 500ms (after warm-up)
- [ ] Frontend loads < 3 seconds
- [ ] All pages functional
- [ ] API documentation accessible
- [ ] CSV download works
- [ ] Regime classification works
- [ ] Mobile responsive
- [ ] No console errors
- [ ] Uptime monitoring configured
- [ ] Team notified of URLs
- [ ] Documentation updated with live URLs

### URLs to Share:

```
Frontend (Dashboard): https://your-app.vercel.app
Backend API: https://your-backend.onrender.com
API Docs: https://your-backend.onrender.com/docs
Health Check: https://your-backend.onrender.com/api/health
```

---

## Cost Estimate

### Free Tier (Recommended for Testing)
- **Render Free**: $0/month (spins down after 15min inactivity)
- **Vercel Free**: $0/month (generous limits)
- **Total**: $0/month

### Production Tier (Recommended for Live)
- **Render Starter**: $7/month (always-on, 1GB RAM)
- **Vercel Free**: $0/month (still sufficient)
- **Total**: ~$7/month

---

## Next Steps After Deployment

1. **Monitor for 24 hours**
   - Check logs regularly
   - Verify no errors
   - Confirm performance metrics

2. **Gather Feedback**
   - Share with team
   - Test all features
   - Document any issues

3. **Optimize** (if needed)
   - Reduce bundle size
   - Add caching
   - Compress assets

4. **Scale** (when ready)
   - Upgrade Render plan if needed
   - Add CDN if traffic increases
   - Consider database for persistence

---

**Good luck with your deployment! 🚀**

For detailed step-by-step instructions, see [DEPLOYMENT.md](DEPLOYMENT.md)
