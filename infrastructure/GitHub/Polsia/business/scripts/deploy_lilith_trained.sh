#!/usr/bin/env bash
# Merge Lilith unified LoRA → GGUF → ollama lilith:latest
set -euo pipefail

ROOT="/home/tehlappy/Desktop/Lilith"
VENV="$ROOT/.venv-train/bin/python3"
ADAPTER="$ROOT/checkpoints/lilith_unified/lilith_unified_adapter"
MERGED="$ROOT/merged_model/lilith_unified"
GGUF_Q4="$MERGED/lilith_unified.gguf"
MODELFILE="$ROOT/Modelfile.lilith"
BASE="${LILITH_TRAIN_BASE:-nvidia/Nemotron-Mini-4B-Instruct}"

if [[ ! -d "$ADAPTER" ]]; then
  echo "Adapter not found: $ADAPTER"
  exit 1
fi

echo "=== Merging Lilith unified adapter ==="
"$VENV" - <<PY
import os, torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel

base = "$BASE"
adapter = "$ADAPTER"
out = "$MERGED"

model = AutoModelForCausalLM.from_pretrained(
    base, torch_dtype=torch.float16, device_map="cpu",
    low_cpu_mem_usage=True, trust_remote_code=True,
)
model = PeftModel.from_pretrained(model, adapter)
model = model.merge_and_unload()
os.makedirs(out, exist_ok=True)
model.save_pretrained(out)
tok = AutoTokenizer.from_pretrained(adapter, trust_remote_code=True)
tok.save_pretrained(out)
print(f"Merged -> {out}")
PY

echo "=== GGUF convert ==="
cd "$ROOT/llama.cpp"
GGUF_WORK="/tmp/lilith_unified_gguf"
rm -rf "$GGUF_WORK" && cp -r "$MERGED" "$GGUF_WORK"
python3 -c "import json; p='$GGUF_WORK/tokenizer_config.json';
import pathlib
if pathlib.Path(p).exists():
 d=json.load(open(p)); d.pop('extra_special_tokens',None); json.dump(d,open(p,'w'),indent=2)"

./.venv/bin/python3 convert_hf_to_gguf.py "$GGUF_WORK" --outfile "$GGUF_WORK/lilith_f16.gguf"
./build/bin/llama-quantize "$GGUF_WORK/lilith_f16.gguf" "$GGUF_Q4" Q4_K_M

# Point Modelfile at trained weights
sed -i "s|^FROM .*|FROM $GGUF_Q4|" "$MODELFILE" 2>/dev/null || true
if ! grep -q "^FROM $GGUF_Q4" "$MODELFILE"; then
  { echo "FROM $GGUF_Q4"; tail -n +2 "$MODELFILE" | grep -v '^FROM '; } > "${MODELFILE}.tmp"
  mv "${MODELFILE}.tmp" "$MODELFILE"
fi

ollama create lilith -f "$MODELFILE"
echo "=== lilith:latest deployed (teacher-distilled) ==="
ollama run lilith:latest "Reply with exactly: LILITH_TRAINED_OK"