#!/bin/bash

WORK_DIR="/home/studio/work"
cd "$WORK_DIR" || { echo "❌ Cannot access $WORK_DIR"; exit 1; }

# Check if WORK_DIR is a uv environment
if [ -f "pyproject.toml" ]; then
    echo "✅ Detected uv environment in $WORK_DIR"
    uv sync

    if [ ! -d ".venv" ]; then
        echo "🧱 Creating virtual environment with uv..."
        uv venv .venv
    else
        echo "📁 .venv already exists. Skipping creation."
    fi

    source .venv/bin/activate

    echo "🧠 Installing ipykernel in uv environment..."
    uv pip install ipykernel

    echo "🧠 Registering Jupyter kernel: python-uv-env"
    uv run python -m ipykernel install --user --name=python-uv-env --display-name "Python (uv env)"

    uv pip install -r requirements.txt

    deactivate
else
    echo "🚫 No uv environment detected in $WORK_DIR"

    # If no uv env, try system-wide install from requirements.txt
    if [ -f "requirements.txt" ]; then
        echo "📦 Installing dependencies globally from requirements.txt using sudo pip..."
        sudo uv pip install -r requirements.txt --system
    else
        echo "ℹ️ No requirements.txt found in $WORK_DIR. Nothing to install."
    fi
fi
