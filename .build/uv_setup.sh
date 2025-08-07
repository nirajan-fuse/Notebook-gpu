#!/bin/bash

WORK_DIR="/home/studio/work"
cd "$WORK_DIR" || { echo "❌ Cannot access $WORK_DIR"; exit 1; }

# Check if WORK_DIR is a uv environment
if [ -d ".venv" ] && [ -f "pyproject.toml" ]; then
    echo "✅ Detected uv environment in $WORK_DIR"
    uv sync
else
    echo "🚀 No uv environment detected in $WORK_DIR. Initializing..."
    uv init
fi

# Install requirements.txt if present
if [ -f "requirements.txt" ]; then
    echo "📦 Installing dependencies from requirements.txt..."
    uv add -r requirements.txt
else
    echo "ℹ️ No requirements.txt found in $WORK_DIR. Skipping dependency install."
fi