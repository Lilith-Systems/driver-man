#!/usr/bin/env fish
# Install Sephirotic Court nervous system API.
set -l ROOT "$HOME/Desktop/Lilith"
set -l SVC "$HOME/.config/systemd/user/sephirotic-court.service"

chmod +x "$ROOT/app/sephirotic_court/server.py"
mkdir -p "$HOME/.config/systemd/user"

printf '%s\n' \
    '[Unit]' \
    'Description=Sephirotic Court — Lilith Nervous System Crown' \
    'After=network.target lilith-wallpaper.service msn-router.service' \
    '' \
    '[Service]' \
    'Type=simple' \
    'WorkingDirectory=/home/tehlappy/Desktop/Lilith/app/sephirotic_court' \
    'Environment=LILITH_ROOT=/home/tehlappy/Desktop/Lilith' \
    'Environment=SEPHIROTIC_COURT_PORT=3215' \
    'ExecStart=/mnt/d/Pub/.venv-pub/bin/python3 /home/tehlappy/Desktop/Lilith/app/sephirotic_court/server.py' \
    'Restart=on-failure' \
    'RestartSec=4' \
    '' \
    '[Install]' \
    'WantedBy=default.target' \
    > $SVC

systemctl --user daemon-reload
systemctl --user enable sephirotic-court.service
systemctl --user restart sephirotic-court.service
sleep 1

ln -sfn "$ROOT/app/sephirotic_court" "$HOME/Desktop/Lilith Sovereign/Sephirotic_Court"
ln -sfn "$ROOT/state/sephirotic_court_nervous_system.json" "$HOME/Desktop/Lilith Sovereign/court_nervous_system.json"

curl -s http://127.0.0.1:3215/api/health | python3 -m json.tool
echo ""
echo "Sephirotic Court: http://127.0.0.1:3215"