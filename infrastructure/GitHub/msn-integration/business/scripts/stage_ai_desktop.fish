#!/usr/bin/env fish
# Stage Desktop/AI loose files → canonical Lilith paths, mirror to D:, sudo 777.
# Invoked via: ai stage

set -l ROOT "$HOME/Desktop/Lilith"
set -l AI "$ROOT/Core_Systems/AI"
set -l ABYSSAL "$AI/abyssal-assets"
set -l CP2077 "$ABYSSAL/cp2077_mods"
set -l STATE "$ROOT/state"
set -l LOG "$ROOT/logs/stage_ai_desktop.log"
set -l MANIFEST "$STATE/ai_desktop_staging_manifest.json"

mkdir -p "$ROOT/logs" "$STATE"
mkdir -p "$AI/scripts/desktop" "$AI/scripts/tesla" "$AI/scripts/msn"
mkdir -p /mnt/d/AI/{archives,grokdata,forex_bots,telemetry,agents,swarms}
mkdir -p /mnt/d/Lilith/{war_chest,evidence,business,exports}
mkdir -p /mnt/d/Cyberpunk/source

function _log
    set -l msg (date -Iseconds)" $argv"
    echo $msg | tee -a $LOG
end

function _stage_path --argument-names src dest
    if not test -e $src
        return 0
    end
    mkdir -p (dirname $dest)
    if test -d $src
        if command -q rsync
            rsync -a --delete $src/ $dest/
        else
            cp -a $src/. $dest/
        end
        _log "SYNC $src -> $dest"
    else if test -f $src -o -L $src
        if test ! -e $dest -o $src -nt $dest
            cp -af $src $dest
            _log "COPY $src -> $dest"
        else
            _log "SKIP (fresh) $dest"
        end
    end
end

function _move_dir --argument-names src dest
    if not test -d $src
        return 0
    end
    if test -L $src
        _log "SKIP symlink $src"
        return 0
    end
    mkdir -p $dest
    if command -q rsync
        rsync -a $src/ $dest/
    else
        cp -a $src/. $dest/
    end
    rm -rf $src
    ln -sfn $dest $src
    _log "LINK $src -> $dest"
end

function _route_loose --argument-names pattern dest_dir
    for f in $AI/$pattern
        if test -e $f -a ! -L $f
            set -l base (basename $f)
            _stage_path $f "$dest_dir/$base"
            if test -f $f
                rm -f $f
                _log "MOVED loose $base -> $dest_dir"
            end
        end
    end
end

_log "=== AI DESKTOP STAGE START (fish) ==="

# ── 1. Desktop entry symlinks ──
ln -sfn $AI "$HOME/Desktop/AI"
ln -sfn /mnt/d/Pub "$AI/Pub"
ln -sfn $ROOT/Core_Systems/GrandTheftCyberpunk "$HOME/Desktop/GrandTheftCyberpunk"
ln -sfn $ROOT/Core_Systems/MSN_Engine "$HOME/Desktop/MSN_Engine"
ln -sfn "$AI/invite" "$HOME/invite"
ln -sfn "$STATE/golem_diary.db" "$AI/memory/golem_diary.db"
ln -sfn "$STATE/golem_diary.db" "$AI/golem_diary.db"
ln -sfn "$STATE/golem_diary.db" /mnt/d/AI/memories/golem_diary.snapshot.db
_log "Desktop symlinks refreshed"

# ── 2. GTC corpora → abyssal + D mirror ──
for pair in gtc_items gtc_quests gtc_space gtc_rebuild
    if test -d "$AI/$pair"
        _stage_path "$AI/$pair" "$ABYSSAL/$pair"
        _stage_path "$AI/$pair" "/mnt/d/Cyberpunk/source/$pair"
        if test -d "$CP2077/$pair"
            _stage_path "$AI/$pair" "$CP2077/$pair"
        end
    end
end

# ── 3. Loose scripts at AI root ──
for f in $AI/*.py $AI/*.sh
    if not test -f $f
        continue
    end
    set -l base (basename $f)
    set -l dest "$AI/scripts/desktop/$base"
    if string match -q 'tesla_*' $base; or string match -q 'email_elon_*' $base; or contains $base ping_elon.py send_nessie_and_hat.py lilith_haunted_car.py
        set dest "$AI/scripts/tesla/$base"
    else if string match -q 'msn_*' $base; or string match -q 'patch*.py' $base; or contains $base deploy-all.sh register_lilith_systems.py plaid_symbiosis_party.py
        set dest "$AI/scripts/msn/$base"
    end
    _stage_path $f $dest
    rm -f $f
end

# ── 4. Archives & datasets → D ──
for f in $AI/*.zip $AI/*.tar.gz
    if test -f $f
        _stage_path $f /mnt/d/AI/archives/(basename $f)
        rm -f $f
    end
end
if test -d "$AI/grokdata_extracted"
    _move_dir "$AI/grokdata_extracted" /mnt/d/AI/grokdata/extracted
end
if test -f "$AI/grokdata.zip"
    _stage_path "$AI/grokdata.zip" /mnt/d/AI/archives/grokdata.zip
    rm -f "$AI/grokdata.zip"
end

# ── 5. Business / evidence / war chest ──
if test -d "$AI/business"
    _stage_path "$AI/business" /mnt/d/Lilith/business/desktop_ai_business
end
if test -d "$AI/War Chest"
    _move_dir "$AI/War Chest" /mnt/d/Lilith/war_chest
end
if test -d "$AI/Evidence"
    _stage_path "$AI/Evidence" /mnt/d/Lilith/evidence/desktop_ai_evidence
end
if test -d "$AI/forex_bots"
    _move_dir "$AI/forex_bots" /mnt/d/AI/forex_bots
end

# ── 6. Agents / antigravity / aethon ──
if test -d "$AI/abyssal-agents"
    _stage_path "$AI/abyssal-agents" "$ABYSSAL/agents/desktop_agents"
end
if test -d "$AI/antigravity"
    _stage_path "$AI/antigravity" /mnt/d/AI/antigravity
end
if test -d "$AI/aethon"
    _stage_path "$AI/aethon" /mnt/d/Pub/aethon-logos
end

# ── 7. State files ──
for f in narrative_state.json cerebellum_map.md
    if test -f "$AI/$f"
        _stage_path "$AI/$f" "$STATE/$f"
        rm -f "$AI/$f"
    end
end

# ── 8. Legacy server/public/skills ──
if test -d "$AI/server" -a ! -e "$ABYSSAL/server/main.py"
    _stage_path "$AI/server" "$ABYSSAL/server"
end
if test -d "$AI/public"
    _stage_path "$AI/public" /mnt/d/Lilith/exports/public
end
if test -d "$AI/skills"
    _stage_path "$AI/skills" /mnt/d/AI/agents/skills
end

# ── 9. Full C/D organize + RAM staging ──
if test -x "$ROOT/scripts/organize_c_d.sh"
    bash "$ROOT/scripts/organize_c_d.sh" 2>&1 | tee -a $LOG
end
if test -x "$HOME/scripts/stage_all_to_ram.sh"
    bash "$HOME/scripts/stage_all_to_ram.sh" 2>&1 | tee -a $LOG
end

# ── 10. sudo 777 sovereign tree ──
if test -x "$ROOT/scripts/ai_desktop_777.sh"
    bash "$ROOT/scripts/ai_desktop_777.sh" 2>&1 | tee -a $LOG
end

# ── 10b. NSSP homescreen wallpaper (Garuda KDE) ──
if test -f "$ROOT/scripts/apply_lilith_wallpaper.fish"
    fish "$ROOT/scripts/apply_lilith_wallpaper.fish" 2>&1 | tee -a $LOG
end

# ── 11. Manifest ──
python3 -c "
import json, os
from datetime import datetime, timezone
from pathlib import Path

ai = Path(os.environ['HOME']) / 'Desktop/Lilith/Core_Systems/AI'
manifest = {
    'schema': 'lilith.ai_desktop_staging.v1',
    'generated': datetime.now(timezone.utc).isoformat(),
    'ai_root': str(ai),
    'loose_files_remaining': sorted(p.name for p in ai.iterdir() if p.is_file()),
    'top_dirs': sorted(p.name for p in ai.iterdir() if p.is_dir() and not p.is_symlink()),
}
out = Path(os.environ['HOME']) / 'Desktop/Lilith/state/ai_desktop_staging_manifest.json'
out.write_text(json.dumps(manifest, indent=2) + '\n')
print(out)
" 2>&1 | tee -a $LOG

_log "=== AI DESKTOP STAGE COMPLETE ==="
echo ""
echo "Manifest: $MANIFEST"
echo "Log:      $LOG"
echo "Run:      ai status"