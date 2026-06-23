#!/bin/bash
export PATH="$HOME/.local/bin:$HOME/.local/google-cloud-sdk/bin:$PATH"
source ~/Desktop/Lilith/.env.gemini 2>/dev/null || true
export GEMINI_API_KEY=$(cat ~/Desktop/butthole.txt 2>/dev/null | tr -d '\n' 2>/dev/null || echo "")
exec gemini "$@"
