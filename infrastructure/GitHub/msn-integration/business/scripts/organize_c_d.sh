#!/usr/bin/env bash
# Lilith C/D Organizer — stage runtime on C (home), archive on D (/mnt/d).
# C = active sovereign runtime | D = cold storage + mod source of truth
set -euo pipefail

ROOT="/home/tehlappy/Desktop/Lilith"
AI_ROOT="$ROOT/Core_Systems/AI"
CP2077_MODS="$AI_ROOT/abyssal-assets/cp2077_mods"
PUB_ORIG="$AI_ROOT/Pub.orig"
PUB_D="/mnt/d/Pub"
D_LILITH="/mnt/d/Lilith"
D_CYBERPUNK="/mnt/d/Cyberpunk"
D_AI="/mnt/d/AI"
STATE="$ROOT/state"
MANIFEST="$STATE/cd_organization_manifest.json"
LOG="$ROOT/logs/organize_c_d.log"
STAGE_RAM="/home/tehlappy/scripts/stage_all_to_ram.sh"

mkdir -p "$STATE" "$ROOT/logs" \
  "$D_LILITH"/{datasets,exports,training,modelfiles} \
  "$D_CYBERPUNK/source" "$D_AI"/{telemetry,memories,agents,swarms}

log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG"; }

symlink_replace() {
  local target="$1" link="$2" backup="$3"
  [[ -e "$target" ]] || { log "SKIP symlink: missing $target"; return 0; }
  if [[ -L "$link" ]]; then
    local cur
    cur="$(readlink -f "$link" 2>/dev/null || readlink "$link")"
    [[ "$cur" == "$(readlink -f "$target")" ]] && { log "OK symlink: $link -> $target"; return 0; }
  fi
  if [[ -e "$link" && ! -L "$link" ]]; then
    if [[ ! -e "$backup" ]]; then
      mv "$link" "$backup"
      log "BACKUP: $link -> $backup"
    else
      log "WARN: backup exists, keeping $link as-is"
      return 0
    fi
  fi
  ln -sfn "$target" "$link"
  log "LINK: $link -> $target"
}

dest_has_content() {
  local dest="$1"
  [[ -d "$dest" ]] || return 1
  [[ -n "$(find "$dest" -mindepth 1 -maxdepth 2 -print -quit 2>/dev/null)" ]]
}

move_to_d() {
  local src="$1" dest="$2"
  [[ -e "$src" ]] || return 0
  if [[ -L "$src" ]]; then
    log "SKIP move (symlink): $src"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  if dest_has_content "$dest"; then
    log "EXISTS (non-empty): $dest — linking back"
  else
    rm -rf "$dest"
    if command -v rsync >/dev/null 2>&1; then
      rsync -a "$src/" "$dest/"
    else
      cp -a "$src" "$dest"
    fi
    log "COPIED: $src -> $dest"
  fi
  rm -rf "$src"
  ln -sfn "$dest" "$src"
  log "LINK: $src -> $dest"
}

sync_cp2077_to_d() {
  local dest_primary="$D_CYBERPUNK/source/primary_mod_source_to_installed_msn_integration"
  log "SYNC cp2077_mods -> $dest_primary"
  mkdir -p "$dest_primary"
  rsync -a --delete \
    --exclude='.git' --exclude='node_modules' --exclude='__pycache__' \
    --exclude='runtime' --exclude='logs' --exclude='output/packed' \
    --exclude='*.pyc' --exclude='.venv*' \
    "$CP2077_MODS/" "$dest_primary/"

  # codegen_cyberpunk.py corpus paths
  local pairs=(
    "msn_core:msn_core"
    "gtc_unified:gtc_unified"
    "msn_weapons:msn_weapons"
    "msn_story:msn_story"
    "abyssal_assets:abyssal_assets"
    "lochness:lochness"
    "lyra:lyra"
    "gtc_rebuild:gtc_rebuild"
    "gtc_items:gtc_items"
    "gtc_quests:gtc_quests"
    "gtc_space:gtc_space"
    "gtc_aethon_sync_mods:gtc_aethon_sync_mods"
    "tools:tools"
  )
  for pair in "${pairs[@]}"; do
    local name="${pair%%:*}"
    local folder="${pair##*:}"
    local src="$CP2077_MODS"
    local sub=""
    case "$name" in
      msn_core|gtc_unified|msn_weapons|msn_story|abyssal_assets|lochness|lyra|gtc_rebuild|gtc_items|gtc_quests|gtc_space|gtc_aethon_sync_mods)
        # Extract from cp2077_mods tree where applicable
        if [[ -d "$CP2077_MODS/$folder" ]]; then
          sub="$CP2077_MODS/$folder"
        elif [[ -d "$AI_ROOT/abyssal-assets/$folder" ]]; then
          sub="$AI_ROOT/abyssal-assets/$folder"
        elif [[ -d "$AI_ROOT/$folder" ]]; then
          sub="$AI_ROOT/$folder"
        fi
        ;;
      tools) sub="$CP2077_MODS/tools" ;;
    esac
    [[ -n "$sub" && -d "$sub" ]] || continue
    mkdir -p "$D_CYBERPUNK/source/$folder"
    rsync -a --delete \
      --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
      "$sub/" "$D_CYBERPUNK/source/$folder/"
    log "SYNC $folder"
  done

  # Bridge + registry touch
  rsync -a "$CP2077_MODS/data/" "$D_CYBERPUNK/bridge/" 2>/dev/null || true
  [[ -f "$CP2077_MODS/info.json" ]] && cp -a "$CP2077_MODS/info.json" "$D_CYBERPUNK/registry/msn_integration_info.json"
}

ensure_desktop_symlinks() {
  ln -sfn "$AI_ROOT" "/home/tehlappy/Desktop/AI"
  ln -sfn "$PUB_D" "/home/tehlappy/Desktop/AI/Pub"
  ln -sfn "$ROOT/Core_Systems/GrandTheftCyberpunk" "/home/tehlappy/Desktop/GrandTheftCyberpunk"
  ln -sfn "$ROOT/Core_Systems/MSN_Engine" "/home/tehlappy/Desktop/MSN_Engine"
  log "Desktop symlinks refreshed"
}

write_manifest() {
  python3 - <<'PY'
import json, os, subprocess
from datetime import datetime, timezone
from pathlib import Path

root = Path("/home/tehlappy/Desktop/Lilith")
state = root / "state"
manifest = {
    "schema": "lilith.cd_organization.v1",
    "generated": datetime.now(timezone.utc).isoformat(),
    "layout": {
        "C_runtime": {
            "lilith_root": str(root),
            "ai_root": str(root / "Core_Systems/AI"),
            "cp2077_mods": str(root / "Core_Systems/AI/abyssal-assets/cp2077_mods"),
            "pub": "/mnt/d/Pub (via Desktop/AI/Pub + Pub.orig symlink)",
            "ram_staging": "/dev/shm/ai_staging",
            "golem_db": "/dev/shm/grok_ram_cache/golem_diary.db",
        },
        "D_storage": {
            "pub": "/mnt/d/Pub",
            "cyberpunk": "/mnt/d/Cyberpunk",
            "lilith": "/mnt/d/Lilith",
            "ai_telemetry": "/mnt/d/AI",
            "games": "/mnt/d/Games",
        },
    },
    "counts": {},
    "sizes": {},
}

def count_glob(base, pattern):
    p = Path(base)
    if not p.exists():
        return 0
    return sum(1 for _ in p.glob(pattern))

def du(path):
    try:
        r = subprocess.run(["du", "-sh", path], capture_output=True, text=True, timeout=30)
        return (r.stdout or "").split()[0] if r.returncode == 0 else "?"
    except Exception:
        return "?"

for label, path in [
    ("gtc_shards_active", "/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/mods/gtc_aethon_sync_*"),
    ("cp2077_mods", str(root / "Core_Systems/AI/abyssal-assets/cp2077_mods")),
    ("d_pub", "/mnt/d/Pub"),
    ("d_cyberpunk_source", "/mnt/d/Cyberpunk/source"),
    ("d_lilith", "/mnt/d/Lilith"),
    ("ram_staging", "/dev/shm/ai_staging"),
]:
    manifest["sizes"][label] = du(path.split("*")[0])

manifest["counts"]["gtc_shards"] = count_glob(
    "/home/tehlappy/.steam/steam/steamapps/common/Cyberpunk 2077/r6/mods", "gtc_aethon_sync_*"
)
manifest["pub_orig_is_symlink"] = (root / "Core_Systems/AI/Pub.orig").is_symlink()
manifest["desktop_ai_is_symlink"] = Path("/home/tehlappy/Desktop/AI").is_symlink()

out = state / "cd_organization_manifest.json"
out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(out)
PY
}

log "=== LILITH C/D ORGANIZE START ==="

# ── 1. Desktop symlinks (C runtime entrypoints) ──
ensure_desktop_symlinks

# ── 2. Pub.orig dedup → D canonical ──
if [[ -d "$PUB_D" ]]; then
  symlink_replace "$PUB_D" "$PUB_ORIG" "${PUB_ORIG}.bak.$(date +%Y%m%d)"
fi

# ── 3. Offload heavy training artifacts C → D ──
for pair in \
  "checkpoints:checkpoints" \
  "models:models" \
  "merged_model:merged_model"; do
  src="$ROOT/${pair%%:*}"
  dest="$D_LILITH/${pair##*:}"
  move_to_d "$src" "$dest"
done

# Datasets stay on C for fast access but mirror to D
if [[ -d "$ROOT/data" ]]; then
  rsync -a --delete \
    --exclude='__pycache__' --exclude='*.pyc' \
    "$ROOT/data/" "$D_LILITH/datasets/" 2>/dev/null || true
  log "MIRROR data -> $D_LILITH/datasets"
fi

# ── 4. Cyberpunk source of truth on D ──
sync_cp2077_to_d

# ── 5. D AI telemetry bucket ──
rsync -a "$ROOT/logs/" "$D_AI/telemetry/lilith_logs/" 2>/dev/null || true
[[ -f "$ROOT/state/golem_diary.db" ]] && \
  cp -a "$ROOT/state/golem_diary.db" "$D_AI/memories/golem_diary.snapshot.db" 2>/dev/null || true

# ── 6. Permissions for organize AI daemons ──
bash "$ROOT/scripts/ai_desktop_777.sh" 2>/dev/null || bash "$ROOT/scripts/stage_lilith_to_ram.sh" 2>/dev/null || true

# ── 7. RAM staging for GPU inference ──
if [[ -x "$STAGE_RAM" ]]; then
  bash "$STAGE_RAM" 2>&1 | tee -a "$LOG" || log "WARN: stage_all_to_ram partial"
else
  log "WARN: $STAGE_RAM missing"
fi

# ── 8. Manifest ──
write_manifest
log "MANIFEST: $MANIFEST"

log "=== LILITH C/D ORGANIZE COMPLETE ==="
echo ""
echo "C (runtime): $ROOT"
echo "D (storage): $D_CYBERPUNK | $D_LILITH | $PUB_D"
echo "Manifest:    $MANIFEST"
du -sh "$ROOT" "$D_LILITH" "$D_CYBERPUNK/source" "$PUB_D" "/dev/shm/ai_staging" 2>/dev/null | sort -hr

# User directive (2026-06-21 kairos): "map C and D only read"
# D is intended as durable/read-mostly archive. Full chmod -R a-w on D subdirs will break future mirrors.
# Use selectively after stable syncs or ro bind mounts (see lilith_post_restart_action_plan).
log "NOTE: C/D 'only read' directive recorded — D treated read-mostly. See action plan for enforcement options."