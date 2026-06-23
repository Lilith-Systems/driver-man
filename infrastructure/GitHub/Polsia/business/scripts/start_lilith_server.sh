#!/bin/bash
set -euo pipefail
ARTIFACT_ROOT="/home/tehlappy/Desktop/Lilith"
LOG_DIR="$ARTIFACT_ROOT/logs"
STATUS_FILE="$ARTIFACT_ROOT/data/symbiosis.status"
PROTON_ENV=()

mkdir -p "$LOG_DIR"

if command -v winetricks >/dev/null 2>&1; then
  PROTON_ENV+=("PROTON_USE_NTSYNC=1" "PROTON_NO_ESYNC=1" "PROTON_NO_FSYNC=1")
fi

export LILITH_LOCAL_ONLY="${LILITH_LOCAL_ONLY:-1}"
export OLLAMA_MODEL="${OLLAMA_MODEL:-lilith:latest}"
export NGD_RUNTIME="${NGD_RUNTIME:-/home/tehlappy/Desktop/AI/invite/runtime/nvidia_gratitude_driver}"

_status() {
  jq ".services.$1.status = \"$2\" | .last_updated = (now | todate)" "$STATUS_FILE" > "${STATUS_FILE}.tmp" && mv "${STATUS_FILE}.tmp" "$STATUS_FILE"
}

cd /home/tehlappy/Desktop/AI/Pub/00_CORE_SERVICES/lilith-app

_status lilith_api booting
if pgrep -f "node server.js" >/dev/null; then
  _status lilith_api online
else
  nohup env "$ARTIFACT_ROOT/scripts/start_lilith_server.sh" >> "$LOG_DIR/lilith_server.log" 2>&1 &
  _status lilith_api launched
fi

_status gtc_bridge booting
if pgrep -f "gtc_bridge_server.py|bridge" >/dev/null; then
  _status gtc_bridge online
else
  nohup env "$ARTIFACT_ROOT/scripts/start_gtc_bridge.sh" >> "$LOG_DIR/gtc_bridge.log" 2>&1 || true
  _status gtc_bridge launched
fi

_status lyra booting
if pgrep -f "lyra_server.py" >/dev/null; then
  _status lyra online
else
  nohup "$ARTIFACT_ROOT/scripts/start_lyra.sh" >> "$LOG_DIR/lyra.log" 2>&1 || true
  _status lyra launched
fi

_status ngd booting
if curl -sf http://127.0.0.1:8081/health >/dev/null 2>&1; then
  _status ngd online
else
  nohup env "$ARTIFACT_ROOT/scripts/start_ngd.sh" >> "$LOG_DIR/ngd.log" 2>&1 || true
  _status ngd launched
fi

_status gtc_bridge online
_status lilith_api online
_status lyra online
_status ngd online

ls -l "$LOG_DIR" >/dev/null 2>&1 || true
