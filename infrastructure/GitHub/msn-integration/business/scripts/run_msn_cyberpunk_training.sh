#!/usr/bin/env bash
# MSN Cyberpunk training: D: source + cp2077_mods → QLoRA → Ollama msn-cyberpunk
set -euo pipefail

ROOT="/home/tehlappy/Desktop/Lilith"
VENV="$ROOT/.venv-train/bin/python3"
LOG="$ROOT/logs/msn_cyberpunk_train.log"

mkdir -p "$ROOT/logs"
echo "=== MSN Cyberpunk Training Pipeline ===" | tee "$LOG"

echo "[1/4] Build dataset (D: Cyberpunk + cp2077_mods + court QA)" | tee -a "$LOG"
"$VENV" "$ROOT/scripts/codegen_cyberpunk.py" 2>&1 | tee -a "$LOG"
"$VENV" "$ROOT/scripts/merge_msn_cyberpunk_dataset.py" 2>&1 | tee -a "$LOG"

echo "[2/4] QLoRA training steps=${MSN_TRAIN_STEPS:-150}" | tee -a "$LOG"
MSN_TRAIN_STEPS="${MSN_TRAIN_STEPS:-150}" "$VENV" "$ROOT/scripts/train_msn_cyberpunk.py" 2>&1 | tee -a "$LOG"

echo "[3/4] Merge adapter + GGUF" | tee -a "$LOG"
bash "$ROOT/scripts/deploy_msn_cyberpunk.sh" 2>&1 | tee -a "$LOG"

echo "[4/4] Verify" | tee -a "$LOG"
ollama list 2>/dev/null | grep -E 'msn|cyberpunk|grok-gtc' | tee -a "$LOG" || true

echo "=== MSN Cyberpunk training complete ===" | tee -a "$LOG"
echo "Test: ollama run msn-cyberpunk 'Explain msn.gaming.engine bootstrap'" | tee -a "$LOG"