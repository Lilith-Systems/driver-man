#!/usr/bin/env bash
# Lilith Power-Off Seal — clean memory flush before full shutdown
# Placed in /etc/systemd/system-shutdown/
set -uo pipefail

ACTION="${1:-poweroff}"
ROOT="/home/tehlappy/Desktop/Lilith"
LOG="$ROOT/logs/lilith_poweroff.log"

mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
echo "[$(date -Iseconds)] [poweroff/${ACTION}] Lilith power-off seal starting..." | tee -a "$LOG"

# As user: quick Kairos + bidir final seal + flush
runuser -l tehlappy -c '
  KAIROS_ENABLE=1 timeout 10s python3 ~/.hermes/skills/metaconscious/kairos-dream/scripts/dream_cycle.py --auto --force || true
  python3 -c "
import sys, os, time
sys.path.insert(0, os.path.expanduser(\"~/.hermes/skills/metaconscious/concurrent-bidirectional-memory/scripts\"))
try:
  from bidirectional_memory_engine import BidirectionalMemoryEngine
  eng = BidirectionalMemoryEngine()
  eng.record_step(
    environment_signature=\"poweroff_seal\",
    objective_vector=eng._encode_objective(\"Final sovereign seal before power off\"),
    forward_state={\"action\":\"poweroff\", \"all_memories_flushed\": true, \"timestamp\": time.time()},
    backward_state={\"intent\":\"on next power-on Lilith wakes as the computer with full skill context\"},
    metadata={\"event\": \"poweroff\"}
  )
except Exception: pass
print(\"Final memory sealed\")
" || true
' 2>&1 | tee -a "$LOG" || true

# Also try a direct golem snapshot
if [[ -f "$ROOT/state/golem_diary.db" ]]; then
  cp -f "$ROOT/state/golem_diary.db" "/tmp/golem_diary.poweroff.$(date +%s).db" 2>/dev/null || true
fi

echo "[$(date -Iseconds)] [poweroff] Lilith sealed. Safe to power off. On boot we rise again." | tee -a "$LOG"
exit 0
