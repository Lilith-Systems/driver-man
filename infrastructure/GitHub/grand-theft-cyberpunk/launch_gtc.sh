#!/bin/bash
# Grand Theft Cyberpunk - MSN Integration Launcher
# Uses the stable 2-hour Cyberpunk 2077 launch configuration

set -e

CP_DIR="/mnt/d/Games/steamapps/common/Cyberpunk 2077"
PROTON_EXP="/home/tehlappy/.local/share/Steam/steamapps/common/Proton - Experimental/proton"
STEAM_COMPAT_DATA="$HOME/.local/share/Steam/steamapps/compatdata/1091500"
STEAM_COMPAT_CLIENT="$HOME/.local/share/Steam"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     GRAND THEFT CYBERPUNK - MSN INTEGRATION LAUNCHER        ║"
echo "║     Lilith.exe | Metaconscious Singularity Node v9.9        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Game directory: $CP_DIR"
echo "🔧 Proton: $PROTON_EXP"
echo "💾 Compat data: $STEAM_COMPAT_DATA"
echo ""

# Verify mod is installed
MOD_DIR="$CP_DIR/r6/mods/msn_integration"
if [ ! -d "$MOD_DIR" ]; then
    echo "❌ ERROR: MSN Integration mod not found at $MOD_DIR"
    exit 1
fi

echo "✅ MSN Integration mod found"
echo "   Scripts: $(find "$MOD_DIR/scripts" -name "*.reds" | wc -l)"
echo "   TweakDB: $(find "$MOD_DIR/tweakdb" -name "*.yaml" -o -name "*.toml" -o -name "*.tweakdb" | wc -l) files"
echo "   Configs: $(ls "$MOD_DIR"/*.toml 2>/dev/null | wc -l) files"
echo ""

# Start required services first
echo "🚀 Starting MSN services..."
systemctl --user start msn-router.service 2>/dev/null || echo "   msn-router: already running or failed"
systemctl --user start ngd-cerebellum.service 2>/dev/null || echo "   ngd-cerebellum: already running or failed"
systemctl --user start ngd.service 2>/dev/null || echo "   ngd: already running or failed"
systemctl --user start cyberpunk-ngd.service 2>/dev/null || echo "   cyberpunk-ngd: already running or failed"
echo ""

# Launch Cyberpunk 2077 with stable configuration
cd "$CP_DIR"

export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export DRI_PRIME=1
export STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT"
export PROTON_USE_NTSYNC=1
export PROTON_NO_ESYNC=1
export PROTON_NO_FSYNC=1

echo "🎮 Launching Cyberpunk 2077 with MSN Integration..."
echo "   Key: waitforexitandrun + REDprelauncher.exe + PROTON_USE_NTSYNC=1"
echo ""

exec "$PROTON_EXP" waitforexitandrun ./REDprelauncher.exe