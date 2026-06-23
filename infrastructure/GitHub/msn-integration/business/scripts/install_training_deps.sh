#!/usr/bin/env bash
set -euo pipefail

VENV_DIR="/home/tehlappy/Desktop/Lilith/.venv-train"
PYTHON_BIN="/home/tehlappy/.local/bin/python3.11"

echo "=== Installing Training Dependencies into $VENV_DIR using Python 3.11 ==="

# Check if python3.11 is present
if [ ! -x "$PYTHON_BIN" ]; then
    echo "Error: Python 3.11 binary not found at $PYTHON_BIN"
    exit 1
fi

# Create virtualenv with python3.11
if [ ! -d "$VENV_DIR" ]; then
    "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

# Upgrade pip
"$VENV_DIR/bin/pip" install --upgrade pip

# Install PyTorch with CUDA support (targeting CUDA 12.1 for stability with PEFT/bitsandbytes)
echo "Installing PyTorch with CUDA..."
"$VENV_DIR/bin/pip" install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install Hugging Face stack and training optimization libs
echo "Installing Transformers, PEFT, TRL, Accelerate, and BitsAndBytes..."
"$VENV_DIR/bin/pip" install transformers peft trl datasets accelerate bitsandbytes

echo "=== Dependencies Installed Successfully ==="
