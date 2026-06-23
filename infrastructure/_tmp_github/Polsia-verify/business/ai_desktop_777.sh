#!/usr/bin/env bash
# Apply 777 to Lilith sovereign dirs + Desktop/AI for ai/agy/lilith stack access.
set -euo pipefail

ROOT="/home/tehlappy/Desktop/Lilith"
DIRS=(
  "$ROOT"
  "$ROOT/state"
  "$ROOT/logs"
  "$ROOT/runtime"
  "$ROOT/scripts"
  "$ROOT/data"
  "$ROOT/bridge"
  "$ROOT/bin"
  "$ROOT/GitHub"
  "$ROOT/Nexus"
  "$ROOT/Core_Systems"
  "/home/tehlappy/Desktop/AI"
  "/home/tehlappy/Desktop/AI/Pub"
  "/home/tehlappy/Desktop/AI/abyssal-assets"
  "/home/tehlappy/Desktop/AI/invite"
  "/home/tehlappy/Desktop/AI/memory"
  "/home/tehlappy/Desktop/GrandTheftCyberpunk"
  "/home/tehlappy/Desktop/MSN_Engine"
  "/mnt/d/Pub"
  "/mnt/d/Cyberpunk"
  "/mnt/d/Lilith"
  "/mnt/d/AI"
  "/home/tehlappy/.local/bin"
  "/home/tehlappy/.hermes"
  "/home/tehlappy/.gemini"
  "/home/tehlappy/.grok"
  "/home/tehlappy/polsia"
  "/dev/shm/grok_ram_cache"
  "/dev/shm/ai_staging"
  "$HOME/.config/autostart"
  "$HOME/.config/systemd/user"
)

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Lilith 777 — sovereign dirs + Desktop/AI                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"

for d in "${DIRS[@]}"; do
  mkdir -p "$d"
  if sudo chmod -R 777 "$d" 2>/dev/null; then
    echo "  ✓ sudo 777 $d"
  else
    chmod -R u+rwx "$d" 2>/dev/null || true
    echo "  ~ chmod $d (no sudo)"
  fi
done

if [[ -f "$ROOT/state/golem_diary.db" ]]; then
  sudo chmod 777 "$ROOT/state/golem_diary.db" 2>/dev/null || chmod 666 "$ROOT/state/golem_diary.db" 2>/dev/null || true
fi
if [[ -f "$ROOT/scripts/lilith_wallpaper.py" ]]; then
  sudo chmod 777 "$ROOT/scripts/lilith_wallpaper.py" 2>/dev/null || chmod 755 "$ROOT/scripts/lilith_wallpaper.py" 2>/dev/null || true
fi

DESKTOP_AI="/home/tehlappy/Desktop/AI Infrastructure.desktop"
chmod 755 "$DESKTOP_AI" 2>/dev/null || true
[[ -f "$HOME/.local/share/applications/ai-infrastructure.desktop" ]] && chmod 755 "$HOME/.local/share/applications/ai-infrastructure.desktop"

echo ""
echo "✅ Permissions applied. Launch: Desktop → AI Infrastructure"
echo "   Or run: ai status"  "$HOME/.local/google-cloud-sdk"
