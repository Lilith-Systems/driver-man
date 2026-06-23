#!/usr/bin/env fish
# Deploy quantum skillset to desktop — 777, RAM/VRAM staging, frontier, himalaya, GitHub.
# Usage: fish ~/Desktop/Lilith/scripts/deploy_quantum_skillset_desktop.fish

set -l ROOT "$HOME/Desktop/Lilith"
set -l LOG "$ROOT/logs/deploy_quantum_skillset.log"
set -l PY (command -v python3)

mkdir -p "$ROOT/logs"
echo (date -Iseconds)" QUANTUM DEPLOY START" | tee -a $LOG

bash "$ROOT/scripts/ai_desktop_777.sh" 2>&1 | tee -a $LOG

$PY "$ROOT/scripts/deploy_quantum_skillset_desktop.py" 2>&1 | tee -a $LOG
set -l code $status

systemctl --user restart lilith-wallpaper.service 2>/dev/null
sleep 2

curl -s -X POST http://127.0.0.1:8009/api/lightning \
    -H "Content-Type: application/json" \
    -d '{"message":"HEART · MIND quantum skillset live on desktop","sephira":"Tiferet","strike":true,"bind_tree":true}' \
    2>/dev/null | tee -a $LOG

echo (date -Iseconds)" QUANTUM DEPLOY DONE exit=$code" | tee -a $LOG
exit $code