#!/usr/bin/env bash
set -euo pipefail
# Stage Lilith model + runtime into RAM for local-first inference.
LILITH_DISK="/home/tehlappy/Desktop/Lilith/ollama-models/gemma-2b-coder-Q4_K_M.gguf"
LILITH_RAM="/dev/shm/lilith/gemma-2b-coder-Q4_K_M.gguf"
STAGING_DIR="/dev/shm/lilith"
mkdir -p "$STAGING_DIR"
if [ ! -f "$LILITH_RAM" ] || [ "$LILITH_DISK" -nt "$LILITH_RAM" ]; then
  cp -a "$LILITH_DISK" "$LILITH_RAM"
  echo "staged $LILITH_DISK -> $LILITH_RAM"
else
  echo "already staged: $LILITH_RAM"
fi
ln -sfn "$LILITH_RAM" "$STAGING_DIR/lilith_q8.gguf"
ln -sfn "$LILITH_RAM" "$STAGING_DIR/lilith.gguf"
ls -lh "$LILITH_RAM"
