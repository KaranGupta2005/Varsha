# PowerShell Deployment Readiness Verification Script for VARSHA

Write-Host "🔍 VARSHA Deployment Readiness Check" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$ERRORS = 0
$WARNINGS = 0

function Check-File {
    param($path)
    if (Test-Path $path) {
        Write-Host "✓ $path exists" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "✗ $path missing" -ForegroundColor Red
        $script:ERRORS++
        return $false
    }
}

function Check-Dir {
    param($path)
    if (Test-Path $path -PathType Container) {
        Write-Host "✓ $path directory exists" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "✗ $path directory missing" -ForegroundColor Red
        $script:ERRORS++
        return $false
    }
}

function Warn {
    param($message)
    Write-Host "⚠ $message" -ForegroundColor Yellow
    $script:WARNINGS++
}

Write-Host "📦 Checking Backend Files..." -ForegroundColor Cyan
Write-Host "----------------------------"
Check-File "backend\requirements.txt"
Check-File "backend\server.py"
Check-File "backend\run_pipeline.py"
Check-File "backend\Dockerfile"
Check-File "backend\.dockerignore"
Check-File "backend\start.sh"
Check-Dir "backend\varsha"

Write-Host ""
Write-Host "🎨 Checking Frontend Files..." -ForegroundColor Cyan
Write-Host "-----------------------------"
Check-File "frontend\package.json"
Check-File "frontend\vite.config.ts"
Check-File "frontend\vercel.json"
Check-File "frontend\.env.example"
Check-File "frontend\.env.production"
Check-Dir "frontend\src"

Write-Host ""
Write-Host "📝 Checking Deployment Configuration..." -ForegroundColor Cyan
Write-Host "---------------------------------------"
Check-File "render.yaml"
Check-File "DEPLOYMENT.md"
Check-File "DEPLOYMENT_CHECKLIST.md"
Check-File "DEPLOYMENT_SUMMARY.md"

Write-Host ""
Write-Host "🔬 Checking Data & Models..." -ForegroundColor Cyan
Write-Host "----------------------------"
if (Test-Path "backend\models\varsha_models.joblib") {
    Write-Host "✓ Models exist (pre-trained)" -ForegroundColor Green
}
else {
    Warn "Models not pre-trained (will be generated during deployment)"
}

if ((Test-Path "frontend\public\data") -and (Test-Path "frontend\public\data\meta.json")) {
    Write-Host "✓ Export data exists" -ForegroundColor Green
}
else {
    Warn "Export data not generated (will be created during deployment)"
}

Write-Host ""
Write-Host "🔧 Checking Backend Dependencies..." -ForegroundColor Cyan
Write-Host "-----------------------------------"
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "✓ Python installed" -ForegroundColor Green
}
else {
    Warn "Python not found (required for local testing)"
}

Write-Host ""
Write-Host "🎨 Checking Frontend Dependencies..." -ForegroundColor Cyan
Write-Host "------------------------------------"
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "✓ Node.js installed" -ForegroundColor Green
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host "✓ npm installed" -ForegroundColor Green
    }
}
else {
    Warn "Node.js/npm not found (required for local testing)"
}

if (Test-Path "frontend\node_modules") {
    Write-Host "✓ npm dependencies installed" -ForegroundColor Green
}
else {
    Warn "npm dependencies not installed (run: npm install)"
}

Write-Host ""
Write-Host "🔍 Checking API URL Configuration..." -ForegroundColor Cyan
Write-Host "------------------------------------"
$envContent = Get-Content "frontend\.env.production" -Raw
if ($envContent -match "varsha-backend\.onrender\.com") {
    Warn "Using placeholder API URL in .env.production"
    Write-Host "    → Update with your actual Render URL after backend deployment" -ForegroundColor Yellow
}
else {
    Write-Host "✓ Custom API URL configured" -ForegroundColor Green
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "📊 Summary" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

if ($ERRORS -eq 0) {
    Write-Host "✓ All critical files present!" -ForegroundColor Green
}
else {
    Write-Host "✗ $ERRORS critical errors found" -ForegroundColor Red
}

if ($WARNINGS -gt 0) {
    Write-Host "⚠ $WARNINGS warnings (optional items)" -ForegroundColor Yellow
}

Write-Host ""

if ($ERRORS -eq 0) {
    Write-Host "🎉 Deployment Ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. git add ."
    Write-Host "2. git commit -m 'Add deployment configurations'"
    Write-Host "3. git push origin main"
    Write-Host "4. Deploy backend to Render (https://dashboard.render.com/)"
    Write-Host "5. Deploy frontend to Vercel (vercel --prod)"
    Write-Host ""
    Write-Host "See DEPLOYMENT_SUMMARY.md for quick start guide"
    exit 0
}
else {
    Write-Host "❌ Not ready for deployment" -ForegroundColor Red
    Write-Host "Please fix the errors above before deploying"
    exit 1
}
