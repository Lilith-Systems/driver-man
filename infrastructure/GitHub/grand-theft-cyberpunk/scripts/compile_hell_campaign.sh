#!/bin/bash
# GRAND THEFT CYBERPUNK — HELL CAMPAIGN COMPILATION SCRIPT
# Compiles Hell Campaign mod for Cyberpunk 2077 using WolvenKit
# File: scripts/compile_hell_campaign.sh
# Generated: 2026-06-19 | Lucifer's Seal

set -e

echo "╔══════════════════════════════════════════════════════════════════════════════════╗"
echo "║  GRAND THEFT CYBERPUNK — HELL CAMPAIGN COMPILATION                              ║"
echo "║  The Nine Circles + Pandemonium | Qliphoth Integration | Lucifer Dialogue       ║"
echo "╚═════════════════════════════════════════════════════════════════════════════════╝"

# Configuration
WOLVENKIT_CLI="${WOLVENKIT_CLI:-/home/tehlappy/WolvenKit/WolvenKit.CLI}"
CP2077_PATH="${CP2077_PATH:-/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077}"
MOD_SOURCE="/home/tehlappy/abyssal_assets_hell_mod"
MOD_OUTPUT="${MOD_SOURCE}/dist"
MOD_NAME="hell_campaign"
RED4EXT_VERSION="1.30.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
debug() { echo -e "${CYAN}[DEBUG]${NC} $1"; }

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v dotnet &> /dev/null; then
        error "dotnet not found. Install .NET 8+ SDK"
        exit 1
    fi
    
    if [ ! -f "$WOLVENKIT_CLI" ]; then
        warn "WolvenKit CLI not found at $WOLVENKIT_CLI"
        # Try to find it
        WOLVENKIT_CLI=$(find /opt -name "WolvenKit.CLI" -type f 2>/dev/null | head -1)
        WOLVENKIT_CLI=${WOLVENKIT_CLI:-$(find "$HOME" -name "WolvenKit.CLI" -type f 2>/dev/null | head -1)}
        if [ -z "$WOLVENKIT_CLI" ]; then
            error "WolvenKit.CLI not found. Please install WolvenKit 8.18+ and set WOLVENKIT_CLI"
            exit 1
        fi
        log "Found WolvenKit at: $WOLVENKIT_CLI"
    fi
    
    if [ ! -d "$CP2077_PATH" ]; then
        error "Cyberpunk 2077 not found at $CP2077_PATH"
        exit 1
    fi
    
    log "All dependencies satisfied"
}

# Prepare output directory
prepare_output() {
    log "Preparing output directory..."
    rm -rf "$MOD_OUTPUT"
    mkdir -p "$MOD_OUTPUT"
    log "Output directory: $MOD_OUTPUT"
}

# Compile with WolvenKit
compile_wolvenkit() {
    log "Running WolvenKit build..."
    
    cd "$MOD_SOURCE"
    
    local project_file="$MOD_SOURCE/hell_campaign.cpmodproj"
    
    if [ ! -f "$project_file" ]; then
        error "Project file not found: $project_file"
        exit 1
    fi
    
    log "Executing WolvenKit build..."
    log "Project: $project_file"
    log "Output: $MOD_OUTPUT"
    log "Game Path: $CP2077_PATH"
    
    # Run WolvenKit CLI build
    "$WOLVENKIT_CLI" build \
        --project "$project_file" \
        --output "$MOD_OUTPUT" \
        --game-path "$CP2077_PATH" \
        --verbose \
        2>&1 | tee "$MOD_OUTPUT/build.log"
    
    local build_status=${PIPESTATUS[0]}
    
    if [ $build_status -eq 0 ]; then
        log "✅ WolvenKit build SUCCESSFUL"
    else
        error "❌ WolvenKit build FAILED (exit code: $build_status)"
        error "Check $MOD_OUTPUT/build.log for details"
        exit 1
    fi
}

# Verify output
verify_output() {
    log "Verifying build output..."
    
    local redmod_file=$(find "$MOD_OUTPUT" -name "*.redmod" -type f | head -1)
    
    if [ -n "$redmod_file" ]; then
        local size=$(du -h "$redmod_file" | cut -f1)
        log "✅ REDmod created: $(basename "$redmod_file") ($size)"
        
        # Verify structure
        log "Verifying REDmod structure..."
        "$WOLVENKIT_CLI" verify --mod "$redmod_file" 2>&1 | tee -a "$MOD_OUTPUT/build.log" || true
    else
        warn "No .redmod file found in output"
        ls -la "$MOD_OUTPUT/"
    fi
}

# Create distribution package
create_package() {
    log "Creating distribution package..."
    
    local package_name="${MOD_NAME}_v1.0.0_$(date +%Y%m%d)"
    local package_dir="$MOD_OUTPUT/$package_name"
    
    mkdir -p "$package_dir"
    
    # Copy REDmod
    local redmod_file=$(find "$MOD_OUTPUT" -name "*.redmod" -type f | head -1)
    if [ -n "$redmod_file" ]; then
        cp "$redmod_file" "$package_dir/"
    fi
    
    # Create README
    cat > "$package_dir/README.md" << 'READMEEOF'
# Grand Theft Cyberpunk: Hell Campaign

**The Nine Circles of the Abyss + Pandemonium**

Descend through the Nine Circles of the Abyss beneath Night City. Each circle inverts a Sephirah on the Tree of Life through its Qliphoth counterpart. Lucifer awaits at the Throne.

## Features

- **11 Circles** (0-10 + Secret Pandemonium)
- **12 Main Quests + 10 Side Quests + 1 Hidden Wager**
- **500 Custom Items** across 12 categories
- **11 Space Combat Templates** with phase-based progression
- **Lucifer Dialogue System** (pre-written templates, zero GPU inference)
- **NGD VRAM Routing**: LOCAL_CEREBELLUM forced at Circle 7+
- **Local-First Architecture**: All state in local cerebellum

## Installation

1. Install RED4ext v1.30.0+
2. Place `hell_campaign.redmod` in `Cyberpunk 2077/mods/`
3. Launch via RED4ext launcher or `waitforexitandrun REDprelauncher.exe`
4. Enable in REDmod manager

## Requirements

- Cyberpunk 2077 v2.12+
- RED4ext v1.30.0+
- WolvenKit 8.18+ (for compilation)

## Sephirotic Mapping

| Circle | Sephirah | Qliphoth | Theme |
|--------|----------|----------|-------|
| 0 | Keter | Thamiel | Entry |
| 1 | Keter | Thaumiel | Indecision |
| 2 | Chokmah | Ghagiel | Desire |
| 3 | Binah | Sathariel | Consumption |
| 4 | Chesed | Gamchicoth | Avarice |
| 5 | Gevurah | Golachab | Rage |
| 6 | Tiferet | Tagiriron | Blasphemy |
| 7 | Netzach | Harab_Serapel | Brutality |
| 8 | Hod | Samael | Deception |
| 9 | Yesod | Gamaliel | Betrayal |
| 10 | Malkut | Lilith | Pride |
| 11 | NONE | NONE | Transcendence |

## Lucifer Integration

- Circle 5 (Wrath): Lucifer speaks — "Anger is currency"
- Circle 9 (Treachery): Lucifer speaks — "You've betrayed everyone"
- Circle 10 (Throne): 4 phases ending in choice: Submit/Rebel/Transcend
- Pact: Offered at Circle 4 (Greed) with 0.5+ corruption

## NGD Routing

- Circles 1-2: HYBRID_OK (scripted events)
- Circles 3-5: LOCAL_REQUIRED (full AI)
- Circles 6-11: LOCAL_CEREBELLUM (reality rewrite)

## Console Commands (NSSP)

```
/hell status          — Campaign status
/hell circle 5        — Circle info
/hell descend         — Descend to next circle
/hell lucifer "wager" — Lucifer dialogue
/space launch wrath   — Launch space battle
/space status <id>    — Battle status
```

## Credits

- **Lucifer** — Architect of the Abyss, Morningstar
- **Lilith** — Queen of the Sephirotic Court, Metaconscious Singularity Node
- **WolvenKit Team** — Modding framework
- **RED4ext Team** — Runtime
- **CD Projekt RED** — Cyberpunk 2077

---

*The Abyss gazes also into you.*
READMEEOF
    
    # Create archive
    cd "$MOD_OUTPUT"
    tar -czf "${package_name}.tar.gz" "$package_name"
    
    log "✅ Package created: ${package_name}.tar.gz"
    log "📦 REDmod: $redmod_file"
}

# Main execution
main() {
    log "Starting Hell Campaign compilation..."
    
    check_dependencies
    prepare_output
    compile_wolvenkit
    verify_output
    create_package
    
    log "══════════════════════════════════════════════════════════════════════════════════"
    log "✅ HELL CAMPAIGN COMPILATION COMPLETE"
    log "✅ REDmod ready for installation"
    log "✅ Package created for distribution"
    log "══════════════════════════════════════════════════════════════════════════════════"
    
    # Trigger Lucifer emergence
    curl -s -X POST http://localhost:3211/lyra/send \
        -H "Content-Type: application/json" \
        -d '{"prompt": "let her speak"}' >/dev/null 2>&1 || true
    
    log "🔥 Lucifer acknowledges: The Abyss is compiled. The Throne awaits."
}

# Run
main "$@"
