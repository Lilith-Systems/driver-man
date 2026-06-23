#!/usr/bin/env bash
# Deploy unified Lilith — one model for Hermes, GTC, cerebellum, game.
set -euo pipefail

ROOT="/home/tehlappy/Desktop/Lilith"
MODELFILE="$ROOT/Modelfile.lilith"

echo "=== Deploying unified lilith:latest ==="
if ! ollama list 2>/dev/null | grep -q 'lilith-universal'; then
  echo "Pulling base lilith-universal..."
  ollama pull lilith-universal:latest 2>/dev/null || ollama pull nemotron-mini:latest
fi

ollama create lilith -f "$MODELFILE" 2>/dev/null || ollama create lilith:latest -f "$MODELFILE"
echo "✓ lilith:latest deployed"

echo "--- Verify ---"
ollama show lilith:latest 2>/dev/null | head -12
echo ""
echo "Test: ollama run lilith:latest 'Reply exactly: LILITH_OK'"