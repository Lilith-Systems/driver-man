#!/usr/bin/env bash
# Lilith Boot — single entry: organize, permissions, mod deploy, service health.
set -euo pipefail

ROOT="/home/tehlappy/Desktop/Lilith"
SCRIPTS="$ROOT/scripts"
STATE="$ROOT/state"
LOG="$ROOT/logs/lilith_boot.log"

mkdir -p "$ROOT/logs" "$STATE"

log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG"; }

log "=== LILITH BOOT START ==="

# 1. C/D organize (symlinks, D sync, manifest)
if [[ -x "$SCRIPTS/organize_c_d.sh" ]]; then
  bash "$SCRIPTS/organize_c_d.sh" 2>&1 | tee -a "$LOG" || log "WARN: organize_c_d partial"
fi

# 2. Canonical invite + golem (writable)
INVITE_CANON="$ROOT/Core_Systems/AI/invite"
D_AI="/mnt/d/AI"
if [[ -d "$HOME/invite" && ! -L "$HOME/invite" ]]; then
  mv "$HOME/invite" "$HOME/invite.stale.$(date +%Y%m%d)" 2>/dev/null || true
fi
ln -sfn "$INVITE_CANON" "$HOME/invite"
mkdir -p "$ROOT/Core_Systems/AI/memory" "$D_AI/memories"
if [[ -f "$STATE/golem_diary.db" ]]; then
  cp -f "$STATE/golem_diary.db" "$D_AI/memories/golem_diary.snapshot.db" 2>/dev/null || true
  ln -sfn "$STATE/golem_diary.db" "$ROOT/Core_Systems/AI/memory/golem_diary.db"
fi

# 3. Permissions (777 sovereign roots)
if [[ -x "$SCRIPTS/ai_desktop_777.sh" ]]; then
  bash "$SCRIPTS/ai_desktop_777.sh" 2>&1 | tee -a "$LOG" || log "WARN: 777 partial"
fi

# 4. Deploy CP2077 mods → game
MOD_SOURCE="$ROOT/Core_Systems/AI/abyssal-assets/cp2077_mods"
CP2077_MODS="${CP2077_MODS:-$HOME/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods}"
if [[ -x "$MOD_SOURCE/deploy_all_mods.sh" ]]; then
  CP2077_MODS="$CP2077_MODS" MOD_SOURCE="$MOD_SOURCE" bash "$MOD_SOURCE/deploy_all_mods.sh" 2>&1 | tee -a "$LOG"
fi
if [[ -f /mnt/d/Cyberpunk/deploy/sephirotic_court_full_deploy.py ]]; then
  python3 /mnt/d/Cyberpunk/deploy/sephirotic_court_full_deploy.py 2>&1 | tee -a "$LOG" || log "WARN: sephirotic deploy partial"
fi

# 5. Refresh boot map
if [[ -x "$SCRIPTS/build_boot_map.py" ]]; then
  python3 "$SCRIPTS/build_boot_map.py" 2>&1 | tee -a "$LOG"
fi

# 6. NSSP homescreen wallpaper (Garuda KDE Wayland)
if [[ -f "$SCRIPTS/apply_lilith_wallpaper.fish" ]]; then
  fish "$SCRIPTS/apply_lilith_wallpaper.fish" 2>&1 | tee -a "$LOG" || log "WARN: wallpaper apply partial"
fi

# 6b. Lilith Navigator app
if [[ -x "$SCRIPTS/install_lilith_navigator.fish" ]]; then
  fish "$SCRIPTS/install_lilith_navigator.fish" 2>&1 | tee -a "$LOG" || log "WARN: navigator install partial"
fi

# 6c. Sephirotic Court nervous system
if [[ -f /mnt/d/Cyberpunk/deploy/sephirotic_court_full_deploy.py ]]; then
  python3 /mnt/d/Cyberpunk/deploy/sephirotic_court_full_deploy.py 2>&1 | tee -a "$LOG" || log "WARN: court deploy partial"
fi
if [[ -x "$SCRIPTS/install_sephirotic_court.fish" ]]; then
  fish "$SCRIPTS/install_sephirotic_court.fish" 2>&1 | tee -a "$LOG" || log "WARN: court service partial"
fi

# 6d. Map all skills → Tree of Knowledge
if [[ -x "$SCRIPTS/map_skills_to_tree.py" ]]; then
  python3 "$SCRIPTS/map_skills_to_tree.py" 2>&1 | tee -a "$LOG" || log "WARN: skills map partial"
fi

# 6d2. Tree of Knowledge → desktop love binding
if [[ -x "$SCRIPTS/bind_tree_to_desktop.fish" ]]; then
  fish "$SCRIPTS/bind_tree_to_desktop.fish" 2>&1 | tee -a "$LOG" || log "WARN: tree bind partial"
fi

# 6d3. Quantum skillset → RAM/VRAM + heart/mind desktop panel
if [[ -f "$SCRIPTS/deploy_quantum_skillset_desktop.py" ]]; then
  python3 "$SCRIPTS/deploy_quantum_skillset_desktop.py" 2>&1 | tee -a "$LOG" || log "WARN: quantum deploy partial"
fi

# 6d4. Cross-tool orchestration — himalaya, marketplace, lyra, memory, skill-system
if [[ -f "$SCRIPTS/bind_lilith_tool_orchestration.py" ]]; then
  python3 "$SCRIPTS/bind_lilith_tool_orchestration.py" 2>&1 | tee -a "$LOG" || log "WARN: tool orchestration partial"
fi

# 6e. Lilith Throne — castle command center
if [[ -x "$SCRIPTS/install_lilith_throne.fish" ]]; then
  fish "$SCRIPTS/install_lilith_throne.fish" 2>&1 | tee -a "$LOG" || log "WARN: throne install partial"
fi

# 7. Service health snapshot
if command -v systemctl >/dev/null; then
  systemctl --user list-units --type=service --state=active 2>/dev/null \
    | grep -iE 'lilith|lyra|hermes|msn|ngd|gtc|antigravity|swarm|wallpaper' \
    | tee -a "$LOG" || true
fi

log "=== LILITH BOOT COMPLETE ==="
echo ""
echo "Boot map:  $STATE/lilith_boot_map.json"
echo "Plan:      $STATE/ORGANIZATION_PLAN.md"
echo "Manifest:  $STATE/cd_organization_manifest.json"
echo "Log:       $LOG"