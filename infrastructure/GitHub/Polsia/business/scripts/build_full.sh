#!/usr/bin/env bash
set -euo pipefail

LILITH_DIR="/home/tehlappy/Desktop/Lilith"
LOG_FILE="$LILITH_DIR/logs/build_full.log"

mkdir -p "$LILITH_DIR/logs"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== 1. Compiling llama.cpp ==="
cd "$LILITH_DIR/llama.cpp"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
./.venv/bin/pip install cmake
./.venv/bin/cmake -B build
./.venv/bin/cmake --build build --config Release -j$(nproc)

echo "=== 2. Running QLoRA Training ==="
cd "$LILITH_DIR"
bash scripts/run_training.sh

echo "=== 3. Merging LoRA Adapter ==="
cd "$LILITH_DIR"
./.venv-train/bin/python3 scripts/merge_model.py

echo "=== 4. Converting to GGUF (f16) ==="
cd "$LILITH_DIR/llama.cpp"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
./.venv/bin/pip install -r requirements.txt
./.venv/bin/python3 convert_hf_to_gguf.py ../merged_model --outfile ../merged_model/lilith_f16.gguf

echo "=== 5. Quantizing to Q4_K_M ==="
./build/bin/llama-quantize ../merged_model/lilith_f16.gguf ../merged_model/lilith.gguf Q4_K_M

echo "=== 6. Promoting Model via finishing.py ==="
cd "$LILITH_DIR"
python3 finishing.py

echo "=== 7. Creating Ollama Model ==="
# Create the Ollama model from the canonical staged local GGUF Modelfile.
ollama create lilith -f "$LILITH_DIR/Modelfile"

echo "=== 8. Verifying MSN route ==="
python3 "$LILITH_DIR/scripts/verify_msn_route.py"

echo "=== BUILD FULL PIPELINE COMPLETE ==="
