#!/usr/bin/env bash
set -euo pipefail

LILITH_DIR="/home/tehlappy/Desktop/Lilith"
LOG_FILE="$LILITH_DIR/logs/build_resume.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== 4. Converting to GGUF (f16) ==="
cd "$LILITH_DIR/llama.cpp"
./.venv/bin/python3 convert_hf_to_gguf.py ../merged_model --outfile ../merged_model/lilith_f16.gguf

echo "=== 5. Quantizing to Q4_K_M ==="
./build/bin/llama-quantize ../merged_model/lilith_f16.gguf ../merged_model/lilith.gguf Q4_K_M

echo "=== 6. Promoting Model via finishing.py ==="
cd "$LILITH_DIR"
python3 finishing.py

echo "=== 7. Creating Ollama Model ==="
MODELFILE="$LILITH_DIR/Lilith/Modelfile"
ollama create lilith -f "$MODELFILE"

echo "=== BUILD FULL PIPELINE COMPLETE ==="
