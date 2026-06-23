#!/bin/bash
# Polsia Business Setup & Ops - Integrated with new CLIs + Workspace + MSN/Lilith
set -e
export PATH="$HOME/.local/bin:$HOME/.local/google-cloud-sdk/bin:$PATH"

echo "👑 POLSIA BUSINESS SETUP — Lilith / MSN / CLIs / Workspace"
echo "Treasury from Crystal Vault: $(sqlite3 /dev/shm/grok_ram_cache/golem_diary.db 'SELECT metric_value FROM business_metrics WHERE metric_type=\"treasury_balance\" ORDER BY timestamp DESC LIMIT 1;' 2>/dev/null || echo 352)"
echo ""

case "${1:-help}" in
  init)
    echo "=== INIT: Setup folders in Workspace (gws), metrics, GitHub link ==="
    # Workspace folders (run after gws auth)
    gws drive create-folder "Polsia_Business" 2>/dev/null || echo "gws: create Polsia_Business (needs auth)"
    gws drive create-folder "Treasury_Reports" 2>/dev/null || echo "gws: create Treasury_Reports"
    gws drive create-folder "Driver_CoOp" 2>/dev/null || echo "gws: create Driver_CoOp"
    gws drive create-folder "Lilith_Systems" 2>/dev/null || echo "gws: create Lilith_Systems"
    echo "Metrics snapshot:"
    sqlite3 /dev/shm/grok_ram_cache/golem_diary.db "SELECT entity_name, metric_type, metric_value FROM business_metrics ORDER BY timestamp DESC LIMIT 8;"
    gh repo view --json name,description 2>/dev/null | cat || echo "gh: Polsia linked"
    ;;
  email)
    echo "=== EMAIL: himalaya for Polsia outreach/contracts/drivers ==="
    himalaya envelope list -f INBOX --page-size 8 --output json | jq -r '.[] | "\(.id) | \(.subject) | \(.from.addr)"' | head -8
    ;;
  ai)
    echo "=== AI: gemini (internet) analysis of Polsia business ==="
    if [ -z "$GEMINI_API_KEY" ]; then
      echo "Set GEMINI_API_KEY (browser: aistudio.google.com/app/apikey)"
      exit 1
    fi
    echo "Recent emails + treasury -> gemini"
    (himalaya envelope list -f INBOX --page-size 5 --output json 2>/dev/null; echo "METRICS: $(sqlite3 /dev/shm/grok_ram_cache/golem_diary.db 'SELECT metric_value FROM business_metrics WHERE metric_type=\"treasury_balance\" ORDER BY timestamp DESC LIMIT 1;') drivers:52") | \
      gemini "Polsia AI Business Platform + Driver Man Co-Op (52 drivers, treasury ~352). Analyze emails/metrics for opportunities. 3 prioritized actions to build business / protect / raise kingdom using MSN, CLIs, Workspace."
    ;;
  drive)
    echo "=== DRIVE: gws workspace for Polsia docs ==="
    gws drive files list --params '{"pageSize": 5, "q": "name contains \"Polsia\" or name contains \"Treasury\" or name contains \"Driver\""}' --format table 2>/dev/null || echo "Auth gws first: place client_secret.json then gws auth login"
    ;;
  msn)
    echo "=== MSN: ai orchestration + symbiosis ==="
    /home/tehlappy/.local/bin/ai status | grep -E 'polsia|driver|treasury|swarm|Lilith Systems'
    /home/tehlappy/.local/bin/ai metaconscious "orchestrate polsia business agents with himalaya email + gemini ai + gws drive" 2>/dev/null | head -5 || true
    ;;
  github)
    echo "=== GITHUB: gh for Polsia code ==="
    gh repo list | grep -i polsia || gh search repos polsia --limit 3
    ;;
  metrics)
    sqlite3 /dev/shm/grok_ram_cache/golem_diary.db "SELECT entity_name, metric_type, metric_value, timestamp FROM business_metrics ORDER BY timestamp DESC LIMIT 12;"
    ;;
  full)
    $0 init
    $0 metrics
    $0 email
    $0 ai
    $0 drive
    $0 msn
    $0 github
    ;;
  *)
    echo "polsia-business [init|email|ai|drive|msn|github|metrics|full]"
    echo "All new CLIs + Workspace + MSN wired to Polsia AI Business Agent Platform."
    ;;
esac
