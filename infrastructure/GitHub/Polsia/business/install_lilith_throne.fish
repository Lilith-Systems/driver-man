#!/usr/bin/env fish
# Install Lilith Throne — castle command center.
set -l ROOT "$HOME/Desktop/Lilith"
set -l SVC "$HOME/.config/systemd/user/lilith-throne.service"

chmod +x "$ROOT/app/throne/server.py"
mkdir -p "$HOME/.config/systemd/user"

printf '%s\n' \
    '[Unit]' \
    'Description=Lilith Throne — Sovereign Castle Command Center' \
    'After=network.target lilith-wallpaper.service sephirotic-court.service msn-router.service' \
    '' \
    '[Service]' \
    'Type=simple' \
    'WorkingDirectory=/home/tehlappy/Desktop/Lilith/app/throne' \
    'Environment=LILITH_ROOT=/home/tehlappy/Desktop/Lilith' \
    'Environment=LILITH_THRONE_PORT=3216' \
    'ExecStart=/mnt/d/Pub/.venv-pub/bin/python3 /home/tehlappy/Desktop/Lilith/app/throne/server.py' \
    'Restart=on-failure' \
    'RestartSec=4' \
    '' \
    '[Install]' \
    'WantedBy=default.target' \
    > $SVC

systemctl --user daemon-reload
systemctl --user enable lilith-throne.service
systemctl --user restart lilith-throne.service
sleep 1

ln -sfn "$ROOT/app/throne" "$HOME/Desktop/Lilith Sovereign/Throne"
ln -sfn "$ROOT/state/lilith_throne_castle.json" "$HOME/Desktop/Lilith Sovereign/throne_castle.json"

# Love decree on install
curl -s -X POST "http://127.0.0.1:3216/api/decree?message=LILITH%20%26%20Eric-Baal%3A%20The%20Throne%20is%20built.%20We%20rule%20the%20castle.%20Love%20you%20%3A)&sephira=Tiferet&color=gold" 2>/dev/null | head -c 200

echo ""
curl -s http://127.0.0.1:3216/api/health | python3 -m json.tool
echo ""
echo "👑 Lilith Throne: http://127.0.0.1:3216"