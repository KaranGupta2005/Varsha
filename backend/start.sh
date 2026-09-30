#!/bin/bash
# Startup script for VARSHA backend on Render

set -e

echo "🚀 Starting VARSHA Backend..."

# Check if models directory exists and has models
if [ ! -d "models" ] || [ ! -f "models/varsha_models.joblib" ]; then
    echo "⚠️  Models not found. Running pipeline to generate..."
    python run_pipeline.py || {
        echo "❌ Pipeline failed. Exiting."
        exit 1
    }
    echo "✅ Models generated successfully"
else
    echo "✅ Models found. Skipping pipeline."
fi

# Check if export data exists
if [ ! -d "../frontend/public/data" ] || [ ! -f "../frontend/public/data/meta.json" ]; then
    echo "⚠️  Export data not found. Running pipeline..."
    python run_pipeline.py || {
        echo "❌ Pipeline failed. Exiting."
        exit 1
    }
    echo "✅ Export data generated successfully"
else
    echo "✅ Export data found. Skipping pipeline."
fi

echo "🌐 Starting uvicorn server..."
exec uvicorn server:app --host 0.0.0.0 --port ${PORT:-8000}
