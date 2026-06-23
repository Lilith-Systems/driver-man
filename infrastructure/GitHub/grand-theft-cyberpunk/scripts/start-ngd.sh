#!/usr/bin/env bash
# Linux start script for NVIDIA Gratitude Driver

RUNTIME="${1:-runtime/nvidia_gratitude_driver}"
INTERVAL="${2:-1.0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$ROOT_DIR/ngd-venv"
PYTHON="$VENV_DIR/bin/python"

if [[ ! -f "$PYTHON" ]]; then
    echo "Virtual environment not found at $VENV_DIR"
    echo "Run: python3 -m venv ngd-venv && ngd-venv/bin/pip install -e ."
    exit 1
fi

RUNTIME_PATH="$(realpath -m "$ROOT_DIR/$RUNTIME")"

exec "$PYTHON" -m ngd.driver --runtime "$RUNTIME_PATH" --interval "$INTERVAL"
