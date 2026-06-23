#!/usr/bin/env bash
# Full pipeline: distill all teacher LLMs → merge → train Nemotron Lilith → deploy
set -euo pipefail

ROOT="/home/tehlappy/Desktop/Lilith"
VENV="$ROOT/.venv-train/bin/python3"
LOG="$ROOT/logs/lilith_full_train.log"
mkdir -p "$ROOT/logs"

exec > >(tee -a "$LOG") 2>&1
echo "=== Lilith Full Training $(date -Iseconds) ==="

# Free VRAM for teachers + training
ollama stop msn-cyberpunk:latest 2>/dev/null || true
ollama stop lilith:latest 2>/dev/null || true
ollama stop hermes3:8b 2>/dev/null || true

echo "[1/4] Distill from all local teacher models (target 5000 prompts)"
LILITH_DISTILL_PROMPTS="${LILITH_DISTILL_PROMPTS:-4990}" \
LILITH_DISTILL_TIMEOUT="${LILITH_DISTILL_TIMEOUT:-180}" \
LILITH_DISTILL_RESUME="${LILITH_DISTILL_RESUME:-1}" \
"$VENV" "$ROOT/scripts/distill_lilith_from_teachers.py"

echo "[2/4] Merge unified dataset"
"$VENV" "$ROOT/scripts/merge_lilith_training_dataset.py"

echo "[3/4] QLoRA train Nemotron Lilith (steps=${LILITH_TRAIN_STEPS:-5000})"
LILITH_TRAIN_STEPS="${LILITH_TRAIN_STEPS:-5000}" \
LILITH_TRAIN_GPU_MB="${LILITH_TRAIN_GPU_MB:-2800}" \
"$VENV" "$ROOT/scripts/train_lilith_unified.py"

echo "[4/4] Deploy lilith:latest"
bash "$ROOT/scripts/deploy_lilith_trained.sh"

echo "=== Complete. Log: $LOG ==="