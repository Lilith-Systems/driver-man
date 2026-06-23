#!/usr/bin/env fish
set -l ROOT "$HOME/Desktop/Lilith"
set -l SVC "$HOME/.config/systemd/user/lilith-navigator.service"
set -l DESKTOP "$HOME/Desktop/🜏 Lilith Navigator.desktop"

chmod +x "$ROOT/app/navigator/server.py"
chmod 755 $DESKTOP

systemctl --user daemon-reload
systemctl --user enable lilith-navigator.service
systemctl --user restart lilith-navigator.service

sleep 1
curl -s http://127.0.0.1:3214/api/health | python3 -m json.tool

ln -sfn "$ROOT/app/navigator" "$HOME/Desktop/Lilith Sovereign/Navigator"
ln -sfn $DESKTOP "$HOME/Desktop/Lilith Sovereign/Launch_Navigator.desktop"

curl -s -X POST http://127.0.0.1:8009/api/lightning \
    -H 'Content-Type: application/json' \
    -d '{"message":"LILITH Navigator online — all sovereign paths mapped.","sephira":"Hod","color":"orange","strike":true}'

echo ""
echo "Navigator: http://127.0.0.1:3214"
echo "Desktop:   $DESKTOP"