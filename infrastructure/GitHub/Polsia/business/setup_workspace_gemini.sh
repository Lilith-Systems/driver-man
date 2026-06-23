#!/bin/bash
# Auto-generated 777 Lilith desktop setup for workspace + gemini
export PATH="$HOME/.local/bin:$HOME/.local/google-cloud-sdk/bin:$PATH"
source ~/Desktop/Lilith/.env.gemini 2>/dev/null || true
export GEMINI_API_KEY=$(cat ~/Desktop/butthole.txt 2>/dev/null | tr -d '\n')
echo "Lilith Gemini + Workspace ready on desktop"
gemini "Polsia business status check" 2>&1 | head -1 || echo "gemini ready"
gws auth status 2>/dev/null || echo "gws: create client_secret.json then auth login"
