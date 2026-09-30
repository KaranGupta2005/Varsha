# VARSHA Deployment Guide

Complete guide for deploying VARSHA to Render (Backend) and Vercel (Frontend).

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Deployment (Render)](#backend-deployment-render)
3. [Frontend Deployment (Vercel)](#frontend-deployment-vercel)
4. [Environment Configuration](#environment-configuration)
5. [Testing Deployment](#testing-deployment)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Accounts Required
- ✅ **GitHub Account** (to push your code)
- ✅ **Render Account** (https://render.com - free tier available)
- ✅ **Vercel Account** (https://vercel.com - free tier available)

### Local Setup (Optional but Recommended)
```bash
# Test locally before deploying
./setup.sh      # Install dependencies
./run.sh        # Run full pipeline and serve at http://localhost:8000
```

---

## Backend Deployment (Render)

### Option 1: Using render.yaml (Recommended)

1. **Push to GitHub**
   ```bash
   cd varsha
   git add .
   git commit -m "Add deployment configurations"
   git push origin main
   ```

2. **Connect to Render**
   - Go to https://dashboard.render.com/
   - Click "New +" → "Blueprint"
   - Connect your GitHub repository
   - Render will automatically detect `render.yaml`
   - Click "Apply"

3. **Configure Environment** (if needed)
   - In Render dashboard, go to your service
   - Navigate to "Environment" tab
   - Add any custom environment variables

### Option 2: Manual Setup

1. **Create New Web Service**
   - Go to https://dashboard.render.com/
   - Click "New +" → "Web Service"
   - Connect your repository
   - Select the `backend` directory as root

2. **Configure Build & Start**
   ```
   Name: varsha-backend
   Region: Oregon (or nearest to you)
   Branch: main
   Root Directory: backend
   Runtime: Python 3
   Build Command: pip install -r requirements.txt && python run_pipeline.py
   Start Command: uvicorn server:app --host 0.0.0.0 --port $PORT
   ```

3. **Advanced Settings**
   ```
   Plan: Starter (or Free for testing)
   Health Check Path: /api/health
   Auto-Deploy: Yes
   ```

4. **Environment Variables**
   ```
   PYTHON_VERSION=3.11.0
   PORT=8000
   ```

5. **Deploy**
   - Click "Create Web Service"
   - Wait for build and deployment (~5-10 minutes)
   - Note your backend URL: `https://varsha-backend.onrender.com`

### Important Notes for Render:

⚠️ **Free Tier Limitations:**
- Spins down after 15 minutes of inactivity
- First request after spin-down takes ~30-60 seconds
- 512 MB RAM limit
- 750 hours/month free compute

💡 **Upgrade to Starter ($7/month) if:**
- You need consistent performance
- RAM limit is exceeded
- You want always-on service

---

## Frontend Deployment (Vercel)

### Method 1: Vercel CLI (Recommended)

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Login to Vercel**
   ```bash
   vercel login
   ```

3. **Deploy from Frontend Directory**
   ```bash
   cd frontend
   vercel
   ```

4. **Follow Prompts**
   ```
   ? Set up and deploy "~/varsha/frontend"? Yes
   ? Which scope? Your personal account
   ? Link to existing project? No
   ? What's your project's name? varsha-dashboard
   ? In which directory is your code located? ./
   ```

5. **Configure Environment Variable**
   ```bash
   vercel env add VITE_API_URL production
   # Enter: https://varsha-backend.onrender.com
   ```

6. **Deploy to Production**
   ```bash
   vercel --prod
   ```

### Method 2: Vercel Dashboard

1. **Import Project**
   - Go to https://vercel.com/new
   - Import your GitHub repository
   - Select `frontend` as root directory

2. **Configure Project**
   ```
   Framework Preset: Vite
   Root Directory: frontend
   Build Command: npm run build
   Output Directory: dist
   Install Command: npm install
   ```

3. **Environment Variables**
   - Click "Environment Variables"
   - Add:
     ```
     Name: VITE_API_URL
     Value: https://varsha-backend.onrender.com
     Environment: Production
     ```

4. **Deploy**
   - Click "Deploy"
   - Wait for build (~2-3 minutes)
   - Your site will be live at: `https://varsha-dashboard.vercel.app`

### Custom Domain (Optional)

1. Go to your Vercel project settings
2. Navigate to "Domains"
3. Add your custom domain
4. Update DNS records as instructed

---

## Environment Configuration

### Backend Environment Variables

The backend uses these configurations:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8000` | Server port (Render sets automatically) |
| `PYTHON_VERSION` | `3.11.0` | Python runtime version |

### Frontend Environment Variables

Create `.env.production` in `frontend/`:

```env
VITE_API_URL=https://varsha-backend.onrender.com
```

**Important:** Replace `varsha-backend.onrender.com` with your actual Render backend URL!

### API Proxy Configuration

The `vercel.json` is configured to proxy API requests:

```json
{
  "rewrites": [
    {
      "source": "/api/:path*",
      "destination": "https://varsha-backend.onrender.com/api/:path*"
    }
  ]
}
```

Update the `destination` URL to match your Render backend.

---

## Testing Deployment

### 1. Test Backend API

```bash
# Health check
curl https://varsha-backend.onrender.com/api/health

# Get metadata
curl https://varsha-backend.onrender.com/api/meta

# API documentation
open https://varsha-backend.onrender.com/docs
```

Expected response:
```json
{
  "status": "ok",
  "mode": "simulated",
  "dates": ["2024-06-01", "2025-09-30"],
  "districts": 726,
  "regimes": ["active", "break", "depression", "coastal", "wd", "normal"]
}
```

### 2. Test Frontend

1. **Open in Browser**
   ```
   https://varsha-dashboard.vercel.app
   ```

2. **Check Console Page**
   - Navigate to Console
   - Check if map loads
   - Verify regime classification works

3. **Check Districts Page**
   - Navigate to Districts
   - Verify district warnings load
   - Test CSV download

4. **Check API Integration**
   - Open browser DevTools (F12)
   - Go to Network tab
   - Navigate through app
   - Verify API calls to backend succeed (200 OK)

### 3. End-to-End Test

```bash
# From your local machine
npm run test:e2e  # If you have e2e tests

# Or manual test
# 1. Open frontend URL
# 2. Select a date
# 3. View forecast
# 4. Download bulletin CSV
# 5. Check regime classification
```

---

## Troubleshooting

### Backend Issues

#### Issue: "Application failed to respond"
**Cause:** Service taking too long to start  
**Solution:**
- Check build logs in Render dashboard
- Ensure `run_pipeline.py` completes successfully
- Consider pre-training models and committing them to repo

#### Issue: "Out of memory"
**Cause:** Exceeding 512MB RAM on free tier  
**Solution:**
- Upgrade to Starter plan ($7/month)
- Optimize model loading (lazy load with `@lru_cache`)
- Reduce dataset size in simulation

#### Issue: "Module not found"
**Cause:** Missing dependency in requirements.txt  
**Solution:**
```bash
cd backend
pip freeze > requirements.txt
git add requirements.txt
git commit -m "Update dependencies"
git push
```

#### Issue: "Cold start delay"
**Cause:** Free tier spins down after inactivity  
**Solution:**
- Upgrade to paid plan for always-on
- Add external uptime monitor (UptimeRobot, etc.)
- Accept 30-60s first request delay

### Frontend Issues

#### Issue: "API calls failing with CORS error"
**Cause:** Backend not configured for frontend domain  
**Solution:**
- Backend already has `allow_origins=["*"]` in CORS middleware
- If still failing, check Render logs for errors

#### Issue: "Environment variable not loading"
**Cause:** Vercel environment variable not set  
**Solution:**
```bash
# Set via CLI
vercel env add VITE_API_URL production

# Or via dashboard
# Go to Project Settings → Environment Variables
```

#### Issue: "Build failing on Vercel"
**Cause:** Node version mismatch or missing dependencies  
**Solution:**
- Add `.nvmrc` to frontend directory:
  ```
  18
  ```
- Verify `package.json` has all dependencies

#### Issue: "404 on refresh"
**Cause:** SPA routing not configured  
**Solution:**
- Already handled in `vercel.json` with fallback to `index.html`
- If using custom server, ensure rewrites are configured

### Data Issues

#### Issue: "No forecast data available"
**Cause:** Models not trained or data not exported  
**Solution:**
```bash
# On your local machine
cd backend
python run_pipeline.py

# Commit the generated files
git add models/ ../frontend/public/data/
git commit -m "Add trained models and exported data"
git push

# Redeploy on Render
```

#### Issue: "Verification metrics show zeros"
**Cause:** Pipeline not run during build  
**Solution:**
- Ensure `run_pipeline.py` runs in build command
- Or commit pre-generated artifacts to repository

---

## Performance Optimization

### Backend

1. **Pre-train models**
   ```bash
   cd backend
   python run_pipeline.py
   git add models/
   git commit -m "Add trained models"
   ```

2. **Use caching**
   - Already implemented with `@lru_cache`
   - Increase cache size if needed

3. **Optimize imports**
   - Import heavy libraries (numpy, sklearn) only when needed
   - Use lazy loading for models

### Frontend

1. **Code splitting**
   ```typescript
   // In vite.config.ts
   build: {
     rollupOptions: {
       output: {
         manualChunks: {
           'deck': ['@deck.gl/core', '@deck.gl/layers'],
           'charts': ['recharts']
         }
       }
     }
   }
   ```

2. **Asset optimization**
   - Images: Use WebP format
   - Compress GeoJSON files
   - Enable Vercel image optimization

3. **CDN caching**
   - Already configured in `vercel.json`
   - Static assets cached for 1 year

---

## Monitoring

### Backend Monitoring (Render)

1. **Render Dashboard**
   - View real-time logs
   - Monitor CPU and memory
   - Track request metrics

2. **Health Check Endpoint**
   ```bash
   # Add to external monitor
   https://varsha-backend.onrender.com/api/health
   ```

### Frontend Monitoring (Vercel)

1. **Vercel Analytics** (Built-in)
   - Enable in project settings
   - Track page views and performance

2. **Vercel Speed Insights**
   ```bash
   npm install @vercel/speed-insights
   ```

---

## Costs

### Free Tier Summary

| Service | Free Tier | Limits |
|---------|-----------|--------|
| **Render** | 750 hours/month | 512 MB RAM, spins down after 15min |
| **Vercel** | Unlimited | 100 GB bandwidth, 100 builds/day |

### Paid Plans (If Needed)

| Service | Starter Plan | Cost |
|---------|--------------|------|
| **Render** | Starter | $7/month (always-on, 1 GB RAM) |
| **Vercel** | Pro | $20/month (team features, advanced analytics) |

**Recommendation for Production:**
- Render Starter: $7/month (backend)
- Vercel Free: $0/month (frontend, generous limits)
- **Total: ~$7/month**

---

## Updating Deployment

### Backend Updates

```bash
git add backend/
git commit -m "Update backend"
git push

# Render auto-deploys on push (if enabled)
# Or manually trigger deploy in dashboard
```

### Frontend Updates

```bash
git add frontend/
git commit -m "Update frontend"
git push

# Vercel auto-deploys on push
# Or: vercel --prod
```

---

## Rollback

### Render

1. Go to Render dashboard
2. Select your service
3. Click "Rollback" → Select previous deployment

### Vercel

```bash
# List deployments
vercel ls

# Rollback to specific deployment
vercel rollback <deployment-url>

# Or via dashboard: Deployments → Select deployment → Promote to Production
```

---

## Security Checklist

- [ ] Backend CORS configured correctly
- [ ] No sensitive data in environment variables committed to git
- [ ] API rate limiting enabled (consider adding)
- [ ] HTTPS enforced (automatic on Render/Vercel)
- [ ] Dependencies updated (`pip list --outdated`, `npm outdated`)
- [ ] API documentation secured (consider auth for `/docs`)

---

## Support & Resources

- **VARSHA Documentation**: [docs/BRAINSTORM.md](docs/BRAINSTORM.md)
- **Render Docs**: https://render.com/docs
- **Vercel Docs**: https://vercel.com/docs
- **FastAPI Deployment**: https://fastapi.tiangolo.com/deployment/
- **Vite Deployment**: https://vitejs.dev/guide/static-deploy.html

---

## Quick Reference Commands

```bash
# Local development
./setup.sh
./run.sh
./dev.sh

# Deploy backend
cd backend
git push origin main  # Auto-deploys to Render

# Deploy frontend
cd frontend
vercel --prod

# Check backend health
curl https://varsha-backend.onrender.com/api/health

# View backend logs
# Render Dashboard → Your Service → Logs

# View frontend deployment
vercel ls

# Rollback frontend
vercel rollback <url>
```

---

**Last Updated**: January 2025  
**Version**: 1.0  
**Project**: VARSHA (SIH26080)
