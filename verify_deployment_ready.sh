#!/bin/bash
# Deployment Readiness Verification Script for VARSHA

set -e

echo "🔍 VARSHA Deployment Readiness Check"
echo "===================================="
echo ""

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 exists"
        return 0
    else
        echo -e "${RED}✗${NC} $1 missing"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 directory exists"
        return 0
    else
        echo -e "${RED}✗${NC} $1 directory missing"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

echo "📦 Checking Backend Files..."
echo "----------------------------"
check_file "backend/requirements.txt"
check_file "backend/server.py"
check_file "backend/run_pipeline.py"
check_file "backend/Dockerfile"
check_file "backend/.dockerignore"
check_file "backend/start.sh"
check_dir "backend/varsha"

echo ""
echo "🎨 Checking Frontend Files..."
echo "-----------------------------"
check_file "frontend/package.json"
check_file "frontend/vite.config.ts"
check_file "frontend/vercel.json"
check_file "frontend/.env.example"
check_file "frontend/.env.production"
check_dir "frontend/src"

echo ""
echo "📝 Checking Deployment Configuration..."
echo "---------------------------------------"
check_file "render.yaml"
check_file "DEPLOYMENT.md"
check_file "DEPLOYMENT_CHECKLIST.md"
check_file "DEPLOYMENT_SUMMARY.md"

echo ""
echo "🔬 Checking Data & Models..."
echo "----------------------------"
if [ -f "backend/models/varsha_models.joblib" ]; then
    echo -e "${GREEN}✓${NC} Models exist (pre-trained)"
else
    warn "Models not pre-trained (will be generated during deployment)"
fi

if [ -d "frontend/public/data" ] && [ -f "frontend/public/data/meta.json" ]; then
    echo -e "${GREEN}✓${NC} Export data exists"
else
    warn "Export data not generated (will be created during deployment)"
fi

echo ""
echo "🔧 Checking Backend Dependencies..."
echo "-----------------------------------"
cd backend
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Python3 installed"
    if python3 -c "import fastapi" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} FastAPI installed"
    else
        warn "FastAPI not installed (will be installed during deployment)"
    fi
else
    warn "Python3 not found (required for local testing)"
fi
cd ..

echo ""
echo "🎨 Checking Frontend Dependencies..."
echo "------------------------------------"
cd frontend
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓${NC} Node.js installed"
    if command -v npm &> /dev/null; then
        echo -e "${GREEN}✓${NC} npm installed"
    fi
else
    warn "Node.js/npm not found (required for local testing)"
fi

if [ -d "node_modules" ]; then
    echo -e "${GREEN}✓${NC} npm dependencies installed"
else
    warn "npm dependencies not installed (run: npm install)"
fi
cd ..

echo ""
echo "🔍 Checking API URL Configuration..."
echo "------------------------------------"
if grep -q "varsha-backend.onrender.com" frontend/.env.production; then
    warn "Using placeholder API URL in .env.production"
    echo "    → Update with your actual Render URL after backend deployment"
else
    echo -e "${GREEN}✓${NC} Custom API URL configured"
fi

echo ""
echo "======================================"
echo "📊 Summary"
echo "======================================"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All critical files present!${NC}"
else
    echo -e "${RED}✗ $ERRORS critical errors found${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warnings (optional items)${NC}"
fi

echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 Deployment Ready!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. git add ."
    echo "2. git commit -m 'Add deployment configurations'"
    echo "3. git push origin main"
    echo "4. Deploy backend to Render (https://dashboard.render.com/)"
    echo "5. Deploy frontend to Vercel (vercel --prod)"
    echo ""
    echo "See DEPLOYMENT_SUMMARY.md for quick start guide"
    exit 0
else
    echo -e "${RED}❌ Not ready for deployment${NC}"
    echo "Please fix the errors above before deploying"
    exit 1
fi
