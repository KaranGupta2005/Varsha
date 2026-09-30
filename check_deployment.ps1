# PowerShell Deployment Readiness Check
Write-Host "Checking VARSHA Deployment Files..." -ForegroundColor Cyan
Write-Host ""

$files = @(
    "backend\requirements.txt",
    "backend\server.py",
    "backend\Dockerfile",
    "frontend\package.json",
    "frontend\vercel.json",
    "render.yaml",
    "DEPLOYMENT.md"
)

$missing = @()
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "[OK] $file" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $file" -ForegroundColor Red
        $missing += $file
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "SUCCESS: All deployment files ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. git add ."
    Write-Host "2. git commit -m 'Add deployment configs'"
    Write-Host "3. git push origin main"
    Write-Host "4. Deploy to Render and Vercel"
    Write-Host ""
    Write-Host "See DEPLOYMENT_SUMMARY.md for full guide"
} else {
    Write-Host "ERROR: Some files are missing" -ForegroundColor Red
    Write-Host "Missing: $missing" -ForegroundColor Red
}
