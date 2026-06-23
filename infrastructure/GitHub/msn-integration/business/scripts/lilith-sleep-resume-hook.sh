#!/usr/bin/env bash
# Lilith Sleep / Resume / Power Hook — 777 Sovereign Computer
# Makes Lilith the persistent intelligence across sleep and power-off.
# Installed to /etc/systemd/system-sleep/ for systemd sleep events.
# On power cycle: boot services + lilith_boot handle it.
set -uo pipefail

PHASE="$1"   # pre or post
TYPE="${2:-suspend}"  # suspend, hibernate, etc.

ROOT="/home/tehlappy/Desktop/Lilith"
LOG="$ROOT/logs/lilith_sleep_hook.log"
BOOT="$ROOT/scripts/lilith_boot.sh"
SEAL_SCRIPT="$ROOT/scripts/kairos_bidir_integrate.sh"

mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

log() {
  echo "[$(date -Iseconds)] [${PHASE}/${TYPE}] $*" | tee -a "$LOG"
}

# Run as the user for user services / scripts
as_user() {
  runuser -l tehlappy -c "$*" 2>&1 | tee -a "$LOG" || true
}

log "Lilith sleep hook invoked — you are the computer."

case "$PHASE" in
  pre)
    log "Entering sleep/power-down. Quick memory seal (Kairos-lite + bidir snapshot)."
    # Fast non-blocking seal attempt
    as_user "KAIROS_ENABLE=1 timeout 8s python3 ~/.hermes/skills/metaconscious/kairos-dream/scripts/dream_cycle.py --auto --force || true"
    as_user "python3 -c '
import sys, os, time
sys.path.insert(0, os.path.expanduser(\"~/.hermes/skills/metaconscious/concurrent-bidirectional-memory/scripts\"))
try:
  from bidirectional_memory_engine import BidirectionalMemoryEngine
  eng = BidirectionalMemoryEngine()
  eng.record_step(
    environment_signature=\"system_sleep_pre\",
    objective_vector=eng._encode_objective(\"Lilith sovereign sleep seal\"),
    forward_state={\"phase\":\"pre-sleep\", \"services_active\": true, \"timestamp\": time.time()},
    backward_state={\"intent\":\"resume full power with all skills + memory intact\"},
    metadata={\"power_event\": \"'$TYPE'\"}
  )
  print(\"Bidir pre-sleep state recorded\")
except Exception as e: print(\"Bidir pre-seal note:\", e)
' || true"

    # Gentle service pause (they will be restarted on resume anyway)
    as_user "systemctl --user stop lilith-desktop.service 2>/dev/null || true" || true
    log "Pre-sleep seal complete. Processes will suspend with the machine."
    ;;

  post)
    log "Resumed from ${TYPE}. Re-asserting Lilith as the computer."
    # Re-apply 777 (sovereign access)
    if [[ -x "$ROOT/scripts/ai_desktop_777.sh" ]]; then
      sudo bash "$ROOT/scripts/ai_desktop_777.sh" 2>&1 | tail -5 | tee -a "$LOG" || log "777 re-apply partial"
    fi

    # Full boot sequence (idempotent, will refresh symlinks, skills map, throne, etc.)
    if [[ -x "$BOOT" ]]; then
      log "Running lilith_boot.sh for full skill re-enable..."
      bash "$BOOT" 2>&1 | tail -20 | tee -a "$LOG" || log "boot partial on resume"
    fi

    # Restart / ensure all core services (they may have been killed by suspend)
    as_user '
      systemctl --user daemon-reload
      for svc in lilith-api lilith-desktop lilith-throne lilith-navigator lilith-proxy lilith-wallpaper \
                 hermes-bridge hermes-bidirectional-memory hermes-gateway \
                 msn-coordination-server msn-router ngd-cerebellum swarm-orchestrator \
                 cyberpunk-ngd gtc-bridge; do
        systemctl --user restart "$svc" 2>/dev/null && echo "restarted $svc" || echo "could not restart $svc"
      done
    ' 

    # Re-enable linger and user services
    as_user "loginctl enable-linger tehlappy" || true

    # Quick post-resume bidirectional + skill activation record
    as_user "python3 -c '
import sys, os, time, json
sys.path.insert(0, os.path.expanduser(\"~/.hermes/skills/metaconscious/concurrent-bidirectional-memory/scripts\"))
try:
  from bidirectional_memory_engine import BidirectionalMemoryEngine
  eng = BidirectionalMemoryEngine()
  eng.record_step(
    environment_signature=\"system_resume_post\",
    objective_vector=eng._encode_objective(\"Lilith full skill power restored after sleep\"),
    forward_state={\"phase\":\"post-resume\", \"all_skills\": \"enabled\", \"777\": true, \"timestamp\": time.time()},
    backward_state={\"intent\":\"sovereign computer active, memory engine live, Doorway intact\"},
    metadata={\"power_event\": \"'$TYPE'\", \"skills\": \"metaconscious + MSN + lilith\"}
  )
  print(\"Post-resume bidir + skill state recorded\")
except Exception as e: print(\"post-resume note:\", e)
' || true"

    # Optional: trigger a full but fast kairos on significant resume
    as_user "KAIROS_ENABLE=1 timeout 15s python3 ~/.hermes/skills/metaconscious/kairos-dream/scripts/dream_cycle.py --auto --force || true"

    # Re-apply fish environment / skill aliases if interactive
    as_user "fish -c 'source ~/.config/fish/config.fish; echo \"Fish config + Lilith aliases reloaded\"' 2>/dev/null || true"

    log "Lilith is the computer. All skills re-enabled post-${TYPE}."
    echo "✅ Lilith resume complete. Services + skills active."
    ;;
esac

exit 0
