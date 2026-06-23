#!/usr/bin/env bash
# Hermes Guard - Check NGD status before local model load
# Usage: hermes-guard.sh [--strict] [--print-status]

set -euo pipefail

STRICT=false
PRINT_STATUS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --strict) STRICT=true; shift ;;
        --print-status) PRINT_STATUS=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

STATUS_FILE="${NGD_STATUS_FILE:-$HOME/invite/runtime/nvidia_gratitude_driver/status.json}"

if [[ ! -f "$STATUS_FILE" ]]; then
    echo "ERROR: NGD status file not found at $STATUS_FILE"
    echo "Is the NVIDIA Gratitude Driver running?"
    exit 1
fi

# Use python for JSON parsing (no jq dependency)
read_status() {
    python3 -c "
import json, sys
with open('$STATUS_FILE') as f:
    data = json.load(f)
route = data.get('route', 'UNKNOWN')
cooldown = data.get('cooldown_active', False)
reason = data.get('reason', 'unknown')
cooldown_rem = data.get('human', {}).get('cooldown_seconds_remaining', 0)
print(f'{route}|{cooldown}|{reason}|{cooldown_rem}')
"
}

IFS='|' read -r route cooldown_active reason cooldown_remaining < <(read_status)

if [[ "$PRINT_STATUS" == true ]]; then
    echo "NGD Status:"
    echo "  Route: $route"
    echo "  Cooldown Active: $cooldown_active"
    echo "  Reason: $reason"
    echo "  Cooldown Remaining: ${cooldown_remaining}s"
fi

# Decision logic
case "$route" in
    LOCAL_CEREBELLUM)
        if [[ "$PRINT_STATUS" == true ]]; then
            echo "✓ LOCAL_CEREBELLUM - Local inference ALLOWED"
        fi
        exit 0
        ;;
    HYBRID)
        if [[ "$PRINT_STATUS" == true ]]; then
            echo "⚠ HYBRID - Local intent parsing ONLY, heavy planning to cloud"
        fi
        if [[ "$STRICT" == true ]]; then
            echo "Strict mode: HYBRID not allowed for heavy inference"
            exit 2
        fi
        exit 0
        ;;
    CLOUD_CORTEX)
        if [[ "$cooldown_active" == "True" ]] || [[ "$cooldown_active" == "true" ]]; then
            if [[ "$PRINT_STATUS" == true ]]; then
                echo "✗ CLOUD_CORTEX (cooldown active) - DO NOT reload local weights"
                echo "  Reason: $reason"
                echo "  Wait: ${cooldown_remaining}s"
            fi
            exit 3
        else
            if [[ "$PRINT_STATUS" == true ]]; then
                echo "⚠ CLOUD_CORTEX (no cooldown) - Cloud route recommended"
            fi
            if [[ "$STRICT" == true ]]; then
                exit 4
            fi
            exit 0
        fi
        ;;
    *)
        echo "⚠ UNKNOWN route: $route - allowing with caution"
        if [[ "$STRICT" == true ]]; then exit 5; fi
        exit 0
        ;;
esac
