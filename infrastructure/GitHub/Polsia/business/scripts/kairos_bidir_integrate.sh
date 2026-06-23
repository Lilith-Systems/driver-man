#!/usr/bin/env bash
# Kairos Dream + Bidirectional Memory + C/D organize + mod deploy + Fish LLM rebuild
set -uo pipefail

ROOT="/home/tehlappy/Desktop/Lilith"
PUB="/mnt/d/Pub"
VENV="$PUB/.venv-pub/bin/python3"
GOLEM="$ROOT/state/golem_diary.db"
LOG="$ROOT/logs/kairos_bidir_integrate.log"

mkdir -p "$ROOT/logs"
log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG"; }

log "=== KAIROS + BIDIR + ORGANIZE START ==="

# Canonical golem for Pub + bidirectional memory
ln -sfn "$GOLEM" "$PUB/golem_diary.db"
ln -sfn "$GOLEM" "$ROOT/Core_Systems/AI/memory/golem_diary.db"

# 1. C/D organize, 777, mod deploy
bash "$ROOT/scripts/lilith_boot.sh" 2>&1 | tee -a "$LOG" || log "WARN: lilith_boot partial"

# 2. Psychology context for terminal agent (hidden from plain shell output)
python3 "$ROOT/scripts/build_psychology_agent_context.py" 2>&1 | tee -a "$LOG"

# 3. Bidirectional memory init + record integration step
export BIDIR_CONFIG="$PUB/config/bidirectional_memory.yaml"
"$VENV" "$HOME/.hermes/skills/metaconscious/concurrent-bidirectional-memory/scripts/bidirectional_memory_engine.py" --init 2>&1 | tee -a "$LOG" || true
"$VENV" - <<'PY' 2>&1 | tee -a "$LOG"
import json, os, sys
sys.path.insert(0, os.path.expanduser("~/.hermes/skills/metaconscious/concurrent-bidirectional-memory/scripts"))
from bidirectional_memory_engine import BidirectionalMemoryEngine
eng = BidirectionalMemoryEngine(os.environ.get("BIDIR_CONFIG"))
obj = eng._encode_objective("MSN engine + Cyberpunk mods + Grok psychology in fish terminal")
eng.record_step(
    environment_signature="fish_terminal",
    objective_vector=obj,
    forward_state={"action": "kairos_bidir_integrate", "mods": "deployed", "fish": "wired"},
    backward_state={"intent": "sovereign_terminal_llm", "recall": "operator_psychology"},
    metadata={"bridge_coherence": 0.88},
)
print(json.dumps({"bidir_recorded": True, "stats": eng.get_stats()}, indent=2))
PY

# 4. Kairos dream consolidation (live writes)
export PUB_ROOT="$PUB"
export HERMES_HOME="$HOME/.hermes"
export KAIROS_ENABLE=1
DREAM="$ROOT/Core_Systems/AI/skills/metaconscious/kairos-dream/scripts/dream_cycle.py"
if [[ -f "$DREAM" ]]; then
  "$VENV" "$DREAM" --auto --force 2>&1 | tee -a "$LOG" || log "WARN: kairos partial"
fi

# 5. Rebuild Lilith Ollama model with psychology in system prompt
if command -v ollama >/dev/null; then
  python3 - <<'PY'
from pathlib import Path
root = Path("/home/tehlappy/Desktop/Lilith")
modelfile = root / "Modelfile.lilith"
psych = (root / "state/operator_psychology_agent_context.txt").read_text(encoding="utf-8").strip()
base = modelfile.read_text(encoding="utf-8")
marker = "OPERATOR PSYCHOLOGY"
if marker not in base:
    insert = f'\n\n# Operator psychology (Grok archive training)\nSYSTEM """{psych}"""\n'
    # Append as additional system block before rebuild — ollama uses last SYSTEM
    out = root / "Modelfile.lilith.psych"
    out.write_text(base.rstrip() + f'\n\nSYSTEM """\n{psych}\n"""\n', encoding="utf-8")
    print(out)
else:
    print(modelfile)
PY
  MF=$(python3 -c "from pathlib import Path; p=Path('/home/tehlappy/Desktop/Lilith/Modelfile.lilith.psych'); print(p if p.is_file() else Path('/home/tehlappy/Desktop/Lilith/Modelfile.lilith'))")
  ollama create lilith -f "$MF" 2>&1 | tee -a "$LOG" || log "WARN: ollama create partial"
  ollama create lilith-universal -f "$MF" 2>&1 | tee -a "$LOG" || true
fi

# 6. Nyx sync (ley + cerebellum)
python3 "$ROOT/scripts/nyx_cerebellum_ley_sync.py" 2>&1 | tee -a "$LOG" || true

log "=== KAIROS + BIDIR + ORGANIZE COMPLETE ==="
echo "Log: $LOG"
echo "Psychology: $ROOT/state/operator_psychology_agent_context.txt"
echo "Fish: lilith | cerebellum | msn | ai status"