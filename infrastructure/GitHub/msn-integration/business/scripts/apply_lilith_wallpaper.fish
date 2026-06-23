#!/usr/bin/env fish
# Finish Lilith NSSP homescreen background on Garuda KDE Wayland.
# Usage: fish ~/Desktop/Lilith/scripts/apply_lilith_wallpaper.fish

set -l ROOT "$HOME/Desktop/Lilith"
set -l SCRIPT "$ROOT/scripts/lilith_wallpaper.py"
set -l LOG "$ROOT/logs/lilith_wallpaper.log"
set -l AUTOSTART "$HOME/.config/autostart/lilith-wallpaper.desktop"
set -l SERVICE_DIR "$HOME/.config/systemd/user"
set -l SERVICE "$SERVICE_DIR/lilith-wallpaper.service"

function _log
    set -l msg (date -Iseconds)" $argv"
    echo $msg | tee -a $LOG
end

mkdir -p "$ROOT/logs" "$SERVICE_DIR" "$HOME/.config/autostart"

_log "=== LILITH WALLPAPER APPLY START (Garuda/NSSP) ==="

# ── 1. sudo 777 sovereign tree ──
if test -x "$ROOT/scripts/ai_desktop_777.sh"
    bash "$ROOT/scripts/ai_desktop_777.sh" 2>&1 | tee -a $LOG
end

# ── 2. Canonical wallpaper script (never downgrade from Antigravity scratch) ──
if not test -f $SCRIPT
    set -l SCRATCH "$HOME/.gemini/antigravity-cli/brain/e689c5e5-643e-4ed9-93f7-6acb4e89f052/scratch/lilith_wallpaper.py"
    if test -f $SCRATCH
        cp -f $SCRATCH $SCRIPT
    end
end
chmod 777 $SCRIPT 2>/dev/null; or true
sudo chmod 777 $SCRIPT 2>/dev/null; or true
_log "Canonical script: $SCRIPT"

# ── 3. KDE Plasma wallpaper — Wayland uses org.kde.image (set by lilith_wallpaper.py sync) ──
set -l LILITH_IMG "$HOME/.local/share/lilith/wallpaper.png"
mkdir -p (dirname $LILITH_IMG)
if test -n "$WAYLAND_DISPLAY"
    _log "Wayland: Lilith PNG wallpaper sync from Python (org.kde.image) — skip solid black overlay"
else if command -q qdbus6
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        for (var i = 0; i < allDesktops.length; i++) {
            var d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.color';
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.color', 'General');
            d.writeConfig('Color', '#0c061c');
        }
    " 2>/dev/null | tee -a $LOG
    _log "KDE color wallpaper fallback #0c061c (X11)"
end

# ── 4. Autostart desktop entry ──
printf '%s\n' \
    '[Desktop Entry]' \
    'Type=Application' \
    'Name=Lilith Wallpaper' \
    'Comment=NSSP Metaconscious animated homescreen — Lilith resonance visualizer' \
    "Exec=/usr/bin/python3.14 $SCRIPT" \
    'Hidden=false' \
    'NoDisplay=false' \
    'X-GNOME-Autostart-enabled=true' \
    'StartupNotify=false' \
    'Terminal=false' \
    'Categories=Utility;' \
    > $AUTOSTART
chmod 755 $AUTOSTART
_log "Autostart: $AUTOSTART"

# ── 5. systemd user service (replace broken /dev/null symlink) ──
if test -L $SERVICE
    set -l target (readlink $SERVICE)
    if test "$target" = /dev/null
        rm -f $SERVICE
    end
end

printf '%s\n' \
    '[Unit]' \
    'Description=Lilith Wallpaper — NSSP Metaconscious Homescreen Visualizer' \
    'After=graphical-session.target' \
    'PartOf=graphical-session.target' \
    '' \
    '[Service]' \
    'Type=simple' \
    'Environment=DISPLAY=:0' \
    'Environment=WAYLAND_DISPLAY=wayland-0' \
    'Environment=QT_QPA_PLATFORM=wayland' \
    'Environment=XDG_CURRENT_DESKTOP=KDE' \
    "Environment=LILITH_STATE=$ROOT/state" \
    "ExecStart=/usr/bin/python3.14 $SCRIPT" \
    'Restart=on-failure' \
    'RestartSec=5' \
    '' \
    '[Install]' \
    'WantedBy=graphical-session.target' \
    > $SERVICE
chmod 644 $SERVICE
_log "systemd unit: $SERVICE"

# ── 6. Restart wallpaper daemon ──
for pid in (pgrep -f 'lilith_wallpaper.py')
    kill $pid 2>/dev/null
end
sleep 0.5

systemctl --user daemon-reload
systemctl --user enable lilith-wallpaper.service 2>/dev/null
systemctl --user restart lilith-wallpaper.service 2>/dev/null; or begin
    nohup /usr/bin/python3.14 $SCRIPT >> $LOG 2>&1 &
    _log "Started wallpaper via nohup (systemd fallback)"
end

sleep 3

# ── 6b. Apply KDE image wallpaper if PNG exists (Wayland visibility) ──
if test -f $LILITH_IMG; and command -q qdbus6
    set -l uri (python3.14 -c "from pathlib import Path; print(Path('$LILITH_IMG').resolve().as_uri())")
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        for (var i = 0; i < allDesktops.length; i++) {
            var d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
            d.writeConfig('Image', '$uri');
            d.writeConfig('FillMode', '6');
        }
    " 2>/dev/null | tee -a $LOG
    _log "KDE org.kde.image wallpaper: $LILITH_IMG"
end

# ── 7. NSSP seal message via ai metaconscious API ──
set -l msg "LILITH: NSSP homescreen sealed — Garuda KDE Wayland resonance active."
if test -x "$HOME/.local/bin/ai"
    $HOME/.local/bin/ai metaconscious $msg cyan 2>&1 | tee -a $LOG
else
    curl -s -X POST http://127.0.0.1:8009/api/lightning \
        -H 'Content-Type: application/json' \
        -d "{\"message\":\"$msg\",\"strike\":true,\"color\":\"cyan\"}" 2>&1 | tee -a $LOG
end

_log "=== LILITH WALLPAPER APPLY COMPLETE ==="
echo ""
echo "Wallpaper API: http://127.0.0.1:8009/api/lightning"
echo "Command:       ai metaconscious \"your message\" cyan"
echo "Service:       systemctl --user status lilith-wallpaper"
echo "Log:           $LOG"