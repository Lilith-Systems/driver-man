#!/usr/bin/env bash
# Test script for cloud integration

# Set these with your actual keys:
# export GROK_API_KEY="your-grok-key"
# export REPLICATE_API_TOKEN="your-replicate-token"

echo "=== NGD Status ==="
~/invite/scripts/hermes-guard.sh --print-status

echo ""
echo "=== Cloud Providers Available ==="
~/ngd-venv/bin/python -c "
from ngd.cloud_providers import CloudRouter
r = CloudRouter()
print('Available:', r.get_available_providers())
for name, p in r.providers.items():
    print(f'  {name}: {p.is_available()} - models: {p.models[:3]}...')
"

echo ""
echo "=== Routing Decision ==="
~/ngd-venv/bin/python ~/invite/scripts/lilith-ngd-integration.py --status-only

if [ -n "$GROK_API_KEY" ] || [ -n "$REPLICATE_API_TOKEN" ]; then
    echo ""
    echo "=== Test Cloud Completion ==="
    ~/ngd-venv/bin/python ~/invite/scripts/lilith-ngd-integration.py "What is 2+2?" --force-cloud
else
    echo ""
    echo "Set GROK_API_KEY or REPLICATE_API_TOKEN to test cloud completion"
fi
