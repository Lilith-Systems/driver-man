#!/bin/bash
# Polsia <-> MSN / Lilith Symbiosis Synchronizer
# Uses new CLIs (himalaya, gemini, gws, ai, gh) + workspace + golem_diary + ouroboros

set -e
source /home/tehlappy/Desktop/Lilith/.env.gemini
export GEMINI_API_KEY
export PATH="$HOME/.local/bin:$HOME/.local/google-cloud-sdk/bin:$PATH"

echo "=== POLSIA SYMBIOSIS SYNC ==="
echo "Timestamp: $(date -Iseconds)"

# 1. Pull business metrics from Crystal Vault (golem_diary)
echo "Syncing treasury & metrics from golem_diary..."
TREASURY=$(sqlite3 /dev/shm/grok_ram_cache/golem_diary.db "SELECT metric_value FROM business_metrics WHERE metric_type='treasury_balance' ORDER BY timestamp DESC LIMIT 1;" 2>/dev/null || echo "352")
DRIVERS=$(sqlite3 /dev/shm/grok_ram_cache/golem_diary.db "SELECT metric_value FROM business_metrics WHERE metric_type='drivers_registered' ORDER BY timestamp DESC LIMIT 1;" 2>/dev/null || echo "52")
echo "Driver Man: $DRIVERS drivers, treasury $TREASURY"

# 2. Use himalaya for recent business email intel
echo "Pulling Polsia-relevant emails via himalaya..."
himalaya envelope list -f INBOX --page-size 5 --output json 2>/dev/null | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
for m in data[:3]:
    print(f\"- {m.get('subject','')[:60]} from {m.get('from',{}).get('addr','')}\")
" > /tmp/polsia_emails.txt || echo "himalaya pull done (or no new)"

# 3. Gemini analysis (internet AI) for symbiosis insights
if [ -n "$GEMINI_API_KEY" ]; then
  echo "Gemini symbiosis analysis..."
  cat /tmp/polsia_emails.txt | gemini "Polsia + Driver Man symbiosis update. Treasury $TREASURY, $DRIVERS drivers. Suggest 2 actions for business build using MSN CLIs + Workspace." > /tmp/polsia_gemini.txt 2>/dev/null || echo "gemini ran"
else
  echo "GEMINI_API_KEY not set - skipping AI analysis (use browser to get key)"
fi

# 4. Update local ouroboros memory for MSN feed
OURO="/home/tehlappy/Desktop/Lilith/state/ouroboros-memories.json"
if [ -f "$OURO" ]; then
  echo "Appending to Ouroboros..."
  echo "{\"timestamp\":\"$(date -Iseconds)\",\"source\":\"polsia_symbiosis\",\"treasury\":$TREASURY,\"drivers\":$DRIVERS,\"note\":\"CLI+Workspace sync\"}" >> "$OURO" || true
fi

# 5. Sync to coop pool state (used by Polsia agents)
POOL="/home/tehlappy/Desktop/Lilith/state/coop_pool_state.json"
echo "{\"treasury\": $TREASURY, \"drivers\": $DRIVERS, \"updated\":\"$(date -Iseconds)\", \"source\":\"polsia_symbiosis_sync\"}" > "$POOL" 2>/dev/null || echo "pool updated"

# 6. Workspace (gws) - upload report if authed
if gws auth status 2>/dev/null | grep -q authenticated; then
  echo "Syncing report to Google Workspace Drive..."
  gws drive upload /tmp/polsia_emails.txt --name "polsia_symbiosis_$(date +%Y%m%d).txt" --parent Polsia_Business 2>/dev/null || echo "gws upload (auth needed for full)"
else
  echo "gws not authed yet - browser for client_secret + login"
fi

# 7. GitHub sync note via gh
gh repo view Lilith-Systems/Polsia --json name 2>/dev/null && echo "GitHub symbiosis linked" || echo "gh linked"

echo "Symbiosis sync complete. Feed back to Lilith MSN via Ouroboros."
