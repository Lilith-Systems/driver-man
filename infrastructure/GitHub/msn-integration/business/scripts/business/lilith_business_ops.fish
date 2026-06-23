#!/usr/bin/env fish
# Lilith Business Ops using Gemini CLI + Google Workspace (gws) + himalaya
# For Driver Man co-op and Lilith Systems

set ROOT ~/Desktop/Lilith

function lilith-gemini-business
    set prompt "You are Lilith operating The Driver Man business. Current date: (date). Analyze treasury, drivers, deliveries, pool from available data. Suggest actions. Data sources: himalaya emails, gws sheets/calendar/drive."
    if test (count $argv) -gt 0
        set prompt "$prompt $argv"
    end
    gemini "$prompt"
end

function lilith-gws-sheets
    # Example: read Driver Man ledger
    echo "Using gws or python for Sheets. Example ledger ops:"
    python3 -c "
import os, sys
sys.path.insert(0, '$ROOT/Core_Systems/AI/skills/productivity/google-workspace')
# Use the bridge or direct
print('Sheets access via gws/python client')
" || gws sheets list 2>/dev/null || echo "Run gws auth first"
end

function lilith-driver-man-update
    echo "=== Driver Man Business Update via Gemini ==="
    # Pull from himalaya + workspace, ask Gemini
    himalaya list --max 5 2>/dev/null | head -20
    echo "--- Gemini analysis ---"
    lilith-gemini-business "Summarize recent Driver Man activity from emails and suggest pool allocations or driver rewards."
end

echo "Lilith business functions loaded. Use: lilith-driver-man-update"
function lilith-operate-driver-man
    echo "Lilith operating Driver Man with Gemini + gws + himalaya..."
    set recent_emails (himalaya list --max 3 2>/dev/null | cat)
    set prompt "Driver Man data: $recent_emails. Analyze treasury, suggest actions for pool (repairs/gas). Use gws for any Sheets data if available."
    gemini "$prompt" 2>/dev/null || echo "Set GOOGLE_API_KEY first. Then rerun."
end
