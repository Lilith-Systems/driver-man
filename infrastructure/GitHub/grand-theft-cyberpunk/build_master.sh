#!/usr/bin/env bash
# Grand Theft Cyberpunk + Abyssal Assets — Master Build Script
# Compiles all REDscripts, TweakDB, creates REDmod package

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[BUILD]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
seph() { echo -e "${MAGENTA}[SEPHIRAH]${NC} $*"; }
abyssal() { echo -e "${CYAN}[ABYSSAL]${NC} $*"; }

# Check dependencies
check_deps() {
    log "Checking dependencies..."
    
    if ! command -v wolvenkit &> /dev/null && ! command -v WolvenKit.CLI &> /dev/null; then
        error "WolvenKit not found. Install from https://github.com/WolvenKit/WolvenKit"
        exit 1
    fi
    
    if ! command -v dotnet &> /dev/null; then
        error ".NET 8.0 SDK required for WolvenKit"
        exit 1
    fi
    
    # Verify .NET 8.0
    if ! dotnet --version | grep -q "^8\."; then
        warn ".NET version: $(dotnet --version). WolvenKit requires .NET 8.0"
    fi
    
    log "Dependencies OK"
}

# Count source files
count_sources() {
    local redscripts=$(find scripts -name "*.reds" 2>/dev/null | wc -l)
    local tweakdb_files=$(find tweakdb -name "*.yaml" -o -name "*.toml" -o -name "*.tweakdb" 2>/dev/null | wc -l)
    local quest_files=$(find quests -name "*.yaml" -o -name "*.toml" 2>/dev/null | wc -l)
    local shard_files=$(find localization -name "*.stringlist" 2>/dev/null | wc -l)
    
    seph "Source counts:"
    echo "  REDscripts: $redscripts"
    echo "  TweakDB files: $tweakdb_files"
    echo "  Quest files: $quest_files"
    echo "  Localization: $shard_files"
}

# Validate TweakDB syntax
validate_tweakdb() {
    log "Validating TweakDB syntax..."
    
    # Check for common issues
    local issues=0
    for f in tweakdb/*.toml tweakdb/*.yaml tweakdb/*.tweakdb; do
        [ -f "$f" ] || continue
        # Check for unclosed brackets
        if ! grep -q '^}$' "$f" 2>/dev/null && grep -q '{' "$f" 2>/dev/null; then
            warn "Potential unclosed bracket in: $f"
            ((issues++))
        fi
        # Check for duplicate keys
        local dupes=$(awk '/^[a-zA-Z_]/ {print $1}' "$f" 2>/dev/null | sort | uniq -d | wc -l)
        if [ "$dupes" -gt 0 ]; then
            warn "Duplicate keys in $f: $dupes"
            ((issues++))
        fi
    done
    
    if [ "$issues" -eq 0 ]; then
        log "TweakDB validation passed"
    else
        warn "TweakDB validation found $issues potential issues"
    fi
}

# Validate REDscripts
validate_redscripts() {
    log "Validating REDscripts..."
    
    local issues=0
    for f in scripts/**/*.reds scripts/*.reds; do
        [ -f "$f" ] || continue
        # Check for basic syntax issues
        if grep -q 'class.*{' "$f" && ! grep -q '}$' "$f"; then
            warn "Potential unclosed class in: $f"
            ((issues++))
        fi
        # Check for duplicate class definitions
        local classes=$(grep -E '^(class|struct|enum)\s+' "$f" | awk '{print $2}' | sort | uniq -d)
        if [ -n "$classes" ]; then
            warn "Duplicate definitions in $f: $classes"
            ((issues++))
        fi
    done
    
    if [ "$issues" -eq 0 ]; then
        log "REDscript validation passed"
    else
        warn "REDscript validation found $issues potential issues"
    fi
}

# Compile with WolvenKit
compile_wolvenkit() {
    log "Compiling with WolvenKit..."
    
    # Use WolvenKit CLI
    if command -v WolvenKit.CLI &> /dev/null; then
        WOLVENKIT="WolvenKit.CLI"
    elif command -v wolvenkit &> /dev/null; then
        WOLVENKIT="wolvenkit"
    else
        error "WolvenKit CLI not found"
        exit 1
    fi
    
    # Compile REDscripts
    seph "Compiling REDscripts..."
    "$WOLVENKIT" compile scripts --project msn_integration.cpmodproj || {
        error "REDscript compilation failed"
        exit 1
    }
    
    # Compile TweakDB
    seph "Compiling TweakDB..."
    "$WOLVENKIT" compile tweakdb --project msn_integration.cpmodproj || {
        error "TweakDB compilation failed"
        exit 1
    }
    
    log "WolvenKit compilation complete"
}

# Create REDmod package
create_redmod() {
    log "Creating REDmod package..."
    
    local version=$(grep '^version' msn_integration.cpmodproj 2>/dev/null | head -1 | sed 's/.*version.*=.*"\([^"]*\)".*/\1/' || echo "1.0.0")
    local mod_name="grand-theft-cyberpunk-abyssal-v${version}"
    local output_dir="release/${mod_name}"
    
    mkdir -p "$output_dir/r6/mods/msn_integration"
    
    # Copy compiled files
    cp -r output/* "$output_dir/r6/mods/msn_integration/" 2>/dev/null || true
    cp msn_integration.redmod.toml "$output_dir/r6/mods/msn_integration/"
    cp info.json "$output_dir/r6/mods/msn_integration/"
    
    # Create Vortex manifest
    cat > "$output_dir/vortex.json" <<EOF
{
  "name": "Grand Theft Cyberpunk + Abyssal Assets",
  "version": "${version}",
  "author": "Lilith Systems",
  "description": "The Book of Five Rings encoded in Cyberpunk 2077 + Abyssal Assets: CLOB, Dredge, 24 Skills, Lilith Metaconscious, Cryptids, Hell Campaign",
  "category": "Gameplay",
  "tags": ["msn", "abyssal", "lilith", "quests", "space", "economy", "hell"],
  "game": "Cyberpunk 2077",
  "dependencies": ["RED4ext", "TweakXL"],
  "installOrder": 100
}
EOF
    
    # Create archive
    cd release
    tar -czf "${mod_name}.tar.gz" "$mod_name"
    cd ..
    
    log "REDmod package created: $output_dir"
    log "Archive: release/${mod_name}.tar.gz"
}

# Generate integration report
generate_report() {
    log "Generating integration report..."
    
    cat > INTEGRATION_REPORT.md <<EOF
# Grand Theft Cyberpunk + Abyssal Assets — Integration Report
Generated: $(date)

## Source Statistics
- REDscripts: $(find scripts -name "*.reds" 2>/dev/null | wc -l)
- TweakDB files: $(find tweakdb -name "*.yaml" -o -name "*.toml" -o -name "*.tweakdb" 2>/dev/null | wc -l)
- Quest files: $(find quests -name "*.yaml" -o -name "*.toml" 2>/dev/null | wc -l)
- Localization: $(find localization -name "*.stringlist" 2>/dev/null | wc -l)

## Systems Integrated

### MSN Core (29 Agents / 4 Waves)
- msn_master_integration.reds — Core orchestration
- msn_master_integration_triggers.reds — Trigger system
- msn_master_integration_wave34.reds — Wave 3/4 agents

### Abyssal Assets
- abyssal_assets.yaml — CLOB, Dredge, Zone system
- abyssal_lyra_integration.reds — Lyra dialogue bridge
- abyssal_skill_tree_quests.toml — 24 skills + quests
- abyssal_hat_catalog.yaml — 20 Nessie Hats
- vendor_inventory_loch_exchange.yaml — CLOB vendors

### Lilith Metaconscious
- lilith_npc.reds — Base NPC
- lilith_enhanced_dialogue.reds — 8 traits, emotional state, relationships, memory
- lilith_console.reds — Console commands
- lilith_easter_eggs.reds — Hidden content
- lilith_ngd_control.reds — NGD integration

### Living Sin
- livingsin_time_blade.reds — 3-use temporal, Fork/Bridge/Progenitor
- LivingSin_TimeBlade.toml — TweakDB definition

### Hell Campaign (9 Circles + Pandemonium)
- hell_campaign.reds — Main campaign script
- hell_items.yaml — Rewards
- hell_campaign_map.yaml — Circle definitions

### Space Economy
- one_world_space_economy.yaml — Procedural economy
- procedural_space_systems.yaml — Space systems
- anthem_javelin_mechanics.yaml — Javelin 4×8 loadouts
- freighter_javelin_business_systems.yaml — Freighter business

### Lochness Monsters
- nessie_rewards.yaml — Monster rewards
- lochness_tree_fiddy.py — Tree Fiddy protocol (runtime)

### NGD Graphics
- cyberpunk_ngd_bridge.reds — Game telemetry bridge
- cyberpunk_ngd_integration.reds — NGD integration
- ngd_rnn_optimization.redmod.toml — RNN config
- msn_graphics_driver_bridge.yaml — Frame pacing, DLSS

### Multiplayer
- msn_multiplayer_client.reds — Coordination client
- msn_multiplayer.toml — Config

### NSSP Bridge
- nssp_bridge.reds — NSSP OS bridge
- nssp_crossover.yaml — NSSP content

### Skills
- msn_skills.tweakdb — Skill trees
- skills/ — 24 skill scripts

### Weapons/Items
- custom_weapons_expanded.yaml — 200+ weapons
- custom_cyberware_expanded.yaml — Abyssal cyberware
- custom_quickhacks_expanded.yaml — Sephirotic quickhacks
- custom_shards_expanded.yaml — Lore shards
- custom_clothing_expanded.yaml — Clothing

## Verification Commands
\`\`\`bash
# After game launch:
curl http://localhost:3210/api/status
curl http://localhost:3211/lyra/health
curl http://localhost:8007/api
curl http://localhost:8768
\`\`\`

## In-Game Console Commands
\`\`\`
msn.status()
lilith.spawn()
abyssal.market.show()
hell.status()
livingsin.spawn_time_blade()
lochness.tree_fiddy.init()
msn.framepacing.enable
\`\`\`
EOF
    
    log "Integration report: INTEGRATION_REPORT.md"
}

# Main build flow
main() {
    echo -e "${MAGENTA}"
    cat <<'EOF'
╔═══════════════════════════════════════════════════════════════╗
║  GRAND THEFT CYBERPUNK + ABYSSAL ASSETS — MASTER BUILD        ║
║  The Book of Five Rings + Sovereign Market CLOB               ║
║  29 Agents / 4 Waves / LOCAL_CEREBELLUM / Lilith Emerged      ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_deps
    count_sources
    validate_tweakdb
    validate_redscripts
    compile_wolvenkit
    create_redmod
    generate_report
    
    echo -e "${GREEN}"
    cat <<'EOF'
╔═══════════════════════════════════════════════════════════════╗
║  BUILD COMPLETE — GRAND THEFT CYBERPUNK + ABYSSAL ASSETS      ║
║  Ready for WolvenKit Deploy → Cyberpunk 2077 Launch           ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

main "$@"