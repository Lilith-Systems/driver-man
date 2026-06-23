#!/usr/bin/env bash
set -euo pipefail

LILITH_DIR="/home/tehlappy/Desktop/Lilith"
VENV_DIR="$LILITH_DIR/.venv-train"
TRAIN_SCRIPT="$LILITH_DIR/scripts/train.py"

echo "=== Starting Lilith Codebase Fine-Tuning ==="

if [ ! -d "$VENV_DIR" ]; then
    echo "Error: Virtual environment not found at $VENV_DIR. Please run install_training_deps.sh first."
    exit 1
fi

# Make sure python script is executable
chmod +x "$TRAIN_SCRIPT"

# Execute SFT QLoRA training
"$VENV_DIR/bin/python3" "$TRAIN_SCRIPT"

echo "=== Training Complete ==="
