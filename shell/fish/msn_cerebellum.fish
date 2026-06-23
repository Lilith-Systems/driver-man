#!/usr/bin/env fish
# MSN Router + Cerebellum (NGD) fish integration
# Connects fish shell to local MSN (port 8007) and AI Engine (port 8009)

set -gx MSN_ROUTER_URL "http://127.0.0.1:8007"
set -gx AI_ENGINE_URL "http://127.0.0.1:8009"
set -gx LILITH_URL "http://127.0.0.1:3210"
set -gx LYRA_URL "http://127.0.0.1:3211"
set -gx SWARM_URL "http://127.0.0.1:8003"

# --- Health Checks ---
function msn_health
    curl -fsS "$MSN_ROUTER_URL/" | jq .
end

function ai_health
    curl -fsS "$AI_ENGINE_URL/health" | jq .
end

function lilith_health
    curl -fsS "$LILITH_URL/api/status" | jq .
end

function all_health
    echo "=== MSN Router (8007) ==="
    msn_health
    echo ""
    echo "=== AI Engine / Cerebellum (8009) ==="
    ai_health
    echo ""
    echo "=== Lilith Sovereign (3210) ==="
    lilith_health
end

# --- MSN Router Commands ---
function msn_route
    set -l prompt "$argv"
    if test -z "$prompt"
        echo "Usage: msn_route <prompt>"
        return 1
    end
    curl -fsS -X POST "$MSN_ROUTER_URL/api/route" \
        -H 'content-type: application/json' \
        -d "{\"prompt\": \"$prompt\"}" | jq .
end

function msn_agents
    curl -fsS "$MSN_ROUTER_URL/api/agents" | jq .
end

function msn_waves
    curl -fsS "$MSN_ROUTER_URL/api/waves" | jq .
end

function msn_status
    curl -fsS "$MSN_ROUTER_URL/api/status" | jq .
end

# --- AI Engine / Cerebellum (NGD) Commands ---
function ai_infer
    set -l prompt "$argv"
    if test -z "$prompt"
        echo "Usage: ai_infer <prompt>"
        return 1
    end
    curl -fsS -X POST "$AI_ENGINE_URL/api/infer" \
        -H 'content-type: application/json' \
        -d "{\"prompt\": \"$prompt\", \"model\": \"hermes3:8b\", \"sephirotic_routing\": true}" | jq .
end

function ai_chat
    set -l messages (jq -n --arg content "$argv" '{messages: [{role: "user", content: $content}]}')
    curl -fsS -X POST "$AI_ENGINE_URL/v1/chat/completions" \
        -H 'content-type: application/json' \
        -d "$messages" | jq .
end

function ai_ngd_status
    curl -fsS "$AI_ENGINE_URL/api/ngd/status" | jq .
end

function ai_memory
    curl -fsS "$AI_ENGINE_URL/api/memory/stats" | jq .
end

# --- Bidirectional Memory Engine ---
function bdm_status
    curl -fsS "$AI_ENGINE_URL/api/bidirectional/status" | jq .
end

function bdm_recall
    set -l steps (math $argv[1] // 3)
    curl -fsS -X POST "$AI_ENGINE_URL/api/bidirectional/recall" \
        -H 'content-type: application/json' \
        -d "{\"steps_back\": $steps}" | jq .
end

# --- Lilith Sovereign ---
function lilith_chat
    set -l prompt "$argv"
    if test -z "$prompt"
        echo "Usage: lilith_chat <prompt>"
        return 1
    end
    curl -fsS -X POST "$LILITH_URL/v1/chat" \
        -H 'content-type: application/json' \
        -d "{\"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]}" | jq -r '.response // .choices[0].message.content // .'
end

function lilith_msn_route
    set -l prompt "$argv"
    if test -z "$prompt"
        echo "Usage: lilith_msn_route <prompt>"
        return 1
    end
    curl -fsS -X POST "$LILITH_URL/api/msn/route" \
        -H 'content-type: application/json' \
        -d "{\"prompt\": \"$prompt\"}" | jq .
end

# --- Swarm Orchestrator ---
function swarm_status
    curl -fsS "$SWARM_URL/api/status" | jq .
end

function swarm_consensus
    set -l prompt "$argv"
    if test -z "$prompt"
        echo "Usage: swarm_consensus <prompt>"
        return 1
    end
    curl -fsS -X POST "$SWARM_URL/api/consensus" \
        -H 'content-type: application/json' \
        -d "{\"prompt\": \"$prompt\"}" | jq .
end

# --- Utility ---
function msn_help
    echo "MSN Router + Cerebellum Fish Integration"
    echo ""
    echo "Health Checks:"
    echo "  all_health          - Check all services"
    echo "  msn_health          - MSN Router (8007)"
    echo "  ai_health           - AI Engine/Cerebellum (8009)"
    echo "  lilith_health       - Lilith (3210)"
    echo ""
    echo "MSN Router:"
    echo "  msn_route <prompt>  - Route prompt through MSN"
    echo "  msn_agents          - List 29 MSN agents"
    echo "  msn_waves           - Show 4 deployment waves"
    echo "  msn_status          - Full MSN status"
    echo ""
    echo "AI Engine / Cerebellum (NGD):"
    echo "  ai_infer <prompt>   - Direct inference with Sephirotic routing"
    echo "  ai_chat <prompt>    - Chat completions endpoint"
    echo "  ai_ngd_status       - NGD Cerebellum optimizer status"
    echo "  ai_memory           - Bidirectional memory stats"
    echo ""
    echo "Bidirectional Memory:"
    echo "  bdm_status          - Engine status"
    echo "  bdm_recall [steps]  - Trigger backward traversal (default 3)"
    echo ""
    echo "Lilith Sovereign:"
    echo "  lilith_chat <prompt>       - Direct Lilith chat"
    echo "  lilith_msn_route <prompt>  - Lilith MSN routing"
    echo ""
    echo "Swarm:"
    echo "  swarm_status        - Swarm orchestrator status"
    echo "  swarm_consensus <prompt>  - 4-archon consensus"
end

# Auto-run health check on source
if status is-interactive
    echo "[msn_cerebellum] Loaded. Run 'msn_help' for commands."
    all_health
end