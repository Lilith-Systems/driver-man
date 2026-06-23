#!/usr/bin/env bash
# Merge MSN Cyberpunk LoRA adapter and deploy to Ollama.
set -euo pipefail

ROOT="/home/tehlappy/Desktop/Lilith"
VENV="$ROOT/.venv-train/bin/python3"
ADAPTER="$ROOT/checkpoints/msn_cyberpunk/msn_cyberpunk_adapter"
MERGED="$ROOT/merged_model/msn_cyberpunk"
GGUF_Q4="$MERGED/msn_cyberpunk.gguf"
MODELFILE="$ROOT/Modelfile.msn-cyberpunk"

if [[ ! -d "$ADAPTER" ]]; then
  echo "Adapter not found: $ADAPTER"
  echo "Run training first: $ROOT/scripts/run_msn_cyberpunk_training.sh"
  exit 1
fi

echo "=== Merging MSN Cyberpunk adapter ==="
"$VENV" - <<'PY'
import os, torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel

base = "Qwen/Qwen2.5-1.5B-Instruct"
adapter = "/home/tehlappy/Desktop/Lilith/checkpoints/msn_cyberpunk/msn_cyberpunk_adapter"
out = "/home/tehlappy/Desktop/Lilith/merged_model/msn_cyberpunk"

model = AutoModelForCausalLM.from_pretrained(base, torch_dtype=torch.float16, device_map="cpu", low_cpu_mem_usage=True)
model = PeftModel.from_pretrained(model, adapter)
model = model.merge_and_unload()
os.makedirs(out, exist_ok=True)
model.save_pretrained(out)
tok = AutoTokenizer.from_pretrained(adapter)
tok.save_pretrained(out)
print(f"Merged -> {out}")
PY

echo "=== Converting to GGUF ==="
cd "$ROOT/llama.cpp"
GGUF_WORK="/tmp/msn_cyberpunk_gguf"
rm -rf "$GGUF_WORK" && cp -r "$MERGED" "$GGUF_WORK"
python3 -c "import json; p='$GGUF_WORK/tokenizer_config.json'; d=json.load(open(p)); d.pop('extra_special_tokens',None); json.dump(d,open(p,'w'),indent=2)"

if [[ -f build/bin/llama-quantize ]]; then
  ./.venv/bin/python3 convert_hf_to_gguf.py "$GGUF_WORK" --outfile "$GGUF_WORK/msn_cyberpunk_f16.gguf"
  ./build/bin/llama-quantize "$GGUF_WORK/msn_cyberpunk_f16.gguf" "$GGUF_Q4" Q4_K_M
else
  echo "llama.cpp not built — cannot produce GGUF"
  exit 1
fi

cat > "$MODELFILE" <<EOF
FROM $GGUF_Q4
PARAMETER temperature 0.6
PARAMETER top_p 0.9
PARAMETER num_ctx 4096

SYSTEM """You are the MSN (Metaconscious Singularity Node) engine for Grand Theft Cyberpunk.
Trained on Cyberpunk mod corpus from /mnt/d/Cyberpunk/source.
Local sovereign inference. Lilith orchestrator. GTC bridge :8766."""
EOF

ollama create msn-cyberpunk -f "$MODELFILE"
echo "=== msn-cyberpunk deployed with trained GGUF ==="
ollama list | grep -E 'msn|cyberpunk'