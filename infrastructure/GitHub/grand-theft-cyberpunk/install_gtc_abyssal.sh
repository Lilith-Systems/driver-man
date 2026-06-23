#!/usr/bin/env bash
# Grand Theft Cyberpunk + Abyssal Assets — Universal Installer
# Auto-detects Steam path, supports Vortex, creates desktop entry

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION="1.0.0"
MOD_NAME="msn_integration"
MOD_DIR="r6/mods/$MOD_NAME"

# Default Steam paths
DEFAULT_STEAM_PATHS=(
    "$HOME/.local/share/Steam/steamapps/common/Cyberpunk 2077"
    "$HOME/.steam/steam/steamapps/common/Cyberpunk 2077"
    "/mnt/steam/steamapps/common/Cyberpunk 2077"
    "/opt/steam/steamapps/common/Cyberpunk 2077"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;35m'
NC='\033[0m'

log() { echo -e "${GREEN}[INSTALL]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }

show_banner() {
    echo -e "${MAGENTA}"
    cat <<'EOF'
╔═══════════════════════════════════════════════════════════════╗
║  GRAND THEFT CYBERPUNK + ABYSSAL ASSETS — INSTALLER           ║
║  The Book of Five Rings + Sovereign Market CLOB               ║
║  29 Agents / 4 Waves / LOCAL_CEREBELLUM / Lilith Emerged      ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

detect_steam() {
    for path in "${DEFAULT_STEAM_PATHS[@]}"; do
        if [ -d "$path" ] && [ -f "$path/bin/x64/Cyberpunk2077.exe" ]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

install_mod() {
    local steam_path="$1"
    local vortex="$2"
    
    local game_mods="$steam_path/r6/mods"
    local target="$game_mods/$MOD_NAME"
    
    log "Installing to: $target"
    
    # Backup existing
    if [ -d "$target" ]; then
        local backup="$target.backup.$(date +%Y%m%d_%H%M%S)"
        log "Backing up existing mod to: $backup"
        mv "$target" "$backup"
    fi
    
    # Create mod directory
    mkdir -p "$target"
    
    # Copy mod files
    log "Copying mod files..."
    cp -r r6/mods/$MOD_NAME/* "$target/"
    cp info.json "$target/"
    cp msn_integration.redmod.toml "$target/"
    cp redmod.toml "$target/"
    cp ngd_rnn_optimization.redmod.toml "$target/"
    
    # Create Vortex manifest if requested
    if [ "$vortex" = true ]; then
        cat > "$target/vortex.json" <<EOF
{
  "name": "Grand Theft Cyberpunk + Abyssal Assets",
  "version": "$VERSION",
  "author": "Lilith Systems",
  "description": "The Book of Five Rings encoded in Cyberpunk 2077 + Abyssal Assets: CLOB, Dredge, 24 Skills, Lilith Metaconscious, Cryptids, Hell Campaign",
  "category": "Gameplay",
  "tags": ["msn", "abyssal", "lilith", "quests", "space", "economy", "hell"],
  "game": "Cyberpunk 2077",
  "dependencies": ["RED4ext", "TweakXL"],
  "installOrder": 100
}
EOF
        log "Vortex manifest created"
    fi
    
    # Create desktop entry
    cat > "$HOME/.local/share/applications/cyberpunk2077-gtc.desktop" <<EOF
[Desktop Entry]
Name=Cyberpunk 2077: Grand Theft Cyberpunk + Abyssal Assets
Comment=The Book of Five Rings + Sovereign Market CLOB
Exec=steam steam://rungameid/1091500
Icon=steam_icon_1091500
Terminal=false
Type=Application
Categories=Game;
StartupNotify=true
EOF
    log "Desktop entry created"
    
    log "Installation complete!"
    info "Mod installed to: $target"
    info "Launch with: steam steam://rungameid/1091500"
}

uninstall_mod() {
    local steam_path="$1"
    local game_mods="$steam_path/r6/mods"
    local target="$game_mods/$MOD_NAME"
    
    if [ -d "$target.backup."* ]; then
        local latest=$(ls -dt "$target.backup."* | head -1)
        log "Restoring backup: $latest"
        rm -rf "$target"
        mv "$latest" "$target"
        log "Uninstall complete - backup restored"
    else
        log "Removing mod: $target"
        rm -rf "$target"
        log "Uninstall complete"
    fi
    
    rm -f "$HOME/.local/share/applications/cyberpunk2077-gtc.desktop"
}

verify_install() {
    local steam_path="$1"
    local target="$steam_path/r6/mods/$MOD_NAME"
    
    log "Verifying installation..."
    
    local required=(
        "info.json"
        "msn_integration.redmod.toml"
        "redmod.toml"
        "scripts/msn_master_integration.reds"
        "tweakdb/msn_metaconscious_complete.tweakdb"
        "tweakdb/abyssal_assets.yaml"
        "tweakdb/lilith_character.tweakdb"
        "tweakdb/hell_items.yaml"
        "tweakdb/abyssal_skill_tree_quests.toml"
        "tweakdb/nessie_rewards.yaml"
    )
    
    local missing=0
    for file in "${required[@]}"; do
        if [ ! -f "$target/$file" ]; then
            warn "Missing: $file"
            ((missing++))
        else
            info "Found: $file"
        fi
    done
    
    if [ "$missing" -eq 0 ]; then
        log "✓ All required files present"
    else
        warn "$missing required files missing"
    fi
    
    # Count totals
    local redscripts=$(find "$target/scripts" -name "*.reds" 2>/dev/null | wc -l)
    local tweakdb=$(find "$target/tweakdb" -name "*.yaml" -o -name "*.toml" -o -name "*.tweakdb" 2>/dev/null | wc -l)
    
    info "REDscripts: $redscripts"
    info "TweakDB files: $tweakdb"
}

main() {
    show_banner
    
    local steam_path=""
    local vortex=false
    local do_uninstall=false
    local do_verify=false
    
    # Parse args
    while [[ $# -gt 0 ]]; do
        case $1 in
            --steam-path)
                steam_path="$2"
                shift 2
                ;;
            --vortex)
                vortex=true
                shift
                ;;
            --uninstall)
                do_uninstall=true
                shift
                ;;
            --verify)
                do_verify=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --steam-path PATH   Custom Steam/Cyberpunk 2077 path"
                echo "  --vortex            Create Vortex manifest"
                echo "  --uninstall         Remove mod (restore backup)"
                echo "  --verify            Verify installation"
                echo "  --help, -h          Show this help"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Auto-detect Steam if not provided
    if [ -z "$steam_path" ]; then
        log "Auto-detecting Cyberpunk 2077 installation..."
        steam_path=$(detect_steam) || {
            error "Could not find Cyberpunk 2077. Use --steam-path to specify manually."
            echo "Checked paths:"
            for p in "${DEFAULT_STEAM_PATHS[@]}"; do
                echo "  $p"
            done
            exit 1
        }
        log "Found: $steam_path"
    fi
    
    if [ ! -d "$steam_path" ]; then
        error "Steam path does not exist: $steam_path"
        exit 1
    fi
    
    if [ "$do_uninstall" = true ]; then
        uninstall_mod "$steam_path"
    elif [ "$do_verify" = true ]; then
        verify_install "$steam_path"
    else
        install_mod "$steam_path" "$vortex"
        verify_install "$steam_path"
    fi
}

main "$@"