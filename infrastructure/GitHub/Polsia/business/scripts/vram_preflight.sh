#!/usr/bin/env bash
set -euo pipefail
pkill -f distill_lilith_from_teachers.py 2>/dev/null || true
ollama stop hermes3:8b 2>/dev/null || true
ollama stop llama3.1:8b 2>/dev/null || true
FREE=$(nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits | head -1 | tr -d ' ')
echo "VRAM free: ${FREE} MiB"
if [ "${FREE}" -ge 4000 ] 2>/dev/null; then exit 0; else exit 1; fi
