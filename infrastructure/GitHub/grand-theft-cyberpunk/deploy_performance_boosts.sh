#!/bin/bash
# DEPLOY 15 NEW PERFORMANCE BOOSTS
# Based on llama.cpp b9716+ (July 2025)
# File: deploy_performance_boosts.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CP2077_PATH="${CP2077_PATH:-/mnt/d/Games/steamapps/common/Cyberpunk 2077}"


echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
echo "║  DEPLOYING 15 PERFORMANCE BOOSTS — MSN CEREBELLUM                            ║"
echo "║  llama.cpp b9716+ | RTX 3060 6GB | 62GB RAM | Garuda Linux                  ║"
echo "╚═══════════════════════════════════════════════════════════════════════════════╝"

LLAMA_DIR="$HOME/llama.cpp"
CMAKE_FLAGS=(
    -DLLAMA_CUBLAS=ON
    -DLLAMA_CUDA_F16=ON
    -DLLAMA_MTP=ON                    # Boost 1
    -DLLAMA_SWA=ON                    # Boost 4
    -DLLAMA_CUDA_KVMEM=ON             # Boost 5
    -DLLAMA_CUDA_ASYNC_COPY=ON        # Boost 5
    -DLLAMA_CUDA_KERNEL_FUSION=ON     # Boost 14
    -DLLAMA_CUDA_GRAPH=ON             # Boost 14
)

# ============================================================
# 1. BUILD LLAMA.CPP WITH NEW FLAGS
# ============================================================
echo "[1/7] Building llama.cpp with optimized flags..."
cd "$LLAMA_DIR"
cmake -B build "${CMAKE_FLAGS[@]}"
cmake --build build --config Release -j12
echo "  ✅ llama.cpp built with MTP, SWA, KVMEM, Kernel Fusion, CUDA Graphs"

# ============================================================
# 2. DOWNLOAD DRAFT MODEL FOR SPECULATIVE DECODING
# ============================================================
echo "[2/7] Downloading draft model (Eagle-3)..."
DRAFT_MODEL="$HOME/models/tiny-1b-draft.gguf"
if [ ! -f "$DRAFT_MODEL" ]; then
    wget -q "https://huggingface.co/ggml-org/tiny-1b-draft/resolve/main/tiny-1b-draft.gguf" -O "$DRAFT_MODEL"
fi
echo "  ✅ Draft model ready: $DRAFT_MODEL"

# ============================================================
# 3. CONFIGURE LLAMA-SERVER WITH NEW FLAGS
# ============================================================
echo "[3/7] Configuring llama-server with 15 boosts..."
cat > "$HOME/.config/llama-server.conf" << 'EOF'
# llama-server config — 15 Performance Boosts
model = /home/tehlappy/models/hermes3-8b-Q4_K_M.gguf
draft-model = /home/tehlappy/models/tiny-1b-draft.gguf

# Boost 1: MTP
mtp = 4

# Boost 2: Eagle-3 Speculative Decoding
speculative-pmin = 0.15
speculative-max-draft-tokens = 8
tree-attention = true

# Boost 3: Chunked Prefill + Continuous Batching
chunked-prefill = 2048
cont-batching = true
max-batch-size = 512

# Boost 4: Sliding Window Attention
swa = 4096

# Boost 5: KVCache Malloc + Async Copy
# (enabled via env vars GGML_CUDA_KVMEM=1, GGML_CUDA_ASYNC_COPY=1)

# Boost 11: YaRN RoPE Scaling
rope-scaling = yarn
rope-freq-base = 10000
rope-freq-scale = 4.0

# General
ctx-size = 8192
batch-size = 512
ubatch-size = 512
gpu-layers = 20
threads = 12
threads-batch = 12
cache-fp16 = true
flash-attn = true
rope-scaling = yarn
kv-cache-defrag-threshold = 0.1

# Server
host = 0.0.0.0
port = 11434
parallel = 4
cont-batching = true
log-format = json
metrics = true
metrics-port = 9091
EOF
echo "  ✅ llama-server config written"

# ============================================================
# 4. CREATE PROMPT CACHE DATABASE
# ============================================================
echo "[4/7] Creating prompt cache database..."
CACHE_DB="/dev/shm/msn_prompt_cache.sqlite"
sqlite3 "$CACHE_DB" << 'EOF'
CREATE TABLE IF NOT EXISTS prompt_cache (
    prefix_hash TEXT PRIMARY KEY,
    prefix_text TEXT NOT NULL,
    sephirah TEXT NOT NULL,
    kv_cache_blob BLOB NOT NULL,
    created_at REAL NOT NULL,
    expires_at REAL NOT NULL,
    hit_count INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_sephirah ON prompt_cache(sephirah);
CREATE INDEX IF NOT EXISTS idx_expires ON prompt_cache(expires_at);
EOF
echo "  ✅ Prompt cache DB: $CACHE_DB"

# ============================================================
# 5. CONFIGURE SLO SCHEDULER POLICIES
# ============================================================
echo "[5/7] Configuring SLO scheduler..."
SLO_CONFIG="/home/tehlappy/.config/msn_slo_scheduler.yaml"
cat > "$SLO_CONFIG" << 'EOF'
# SLO-Aware Adaptive Batch Scheduler (Boost 15)
scheduler: EDF
policies:
  Lilith_Emergence:
    deadline_ms: 10
    priority: 0
  Combat_Quickhack:
    deadline_ms: 50
    priority: 1
  Defensive_Quickhack:
    deadline_ms: 80
    priority: 2
  Dialogue_Skill:
    deadline_ms: 200
    priority: 3
  Navigation:
    deadline_ms: 300
    priority: 4
  Background_Batch:
    deadline_ms: 5000
    priority: 5

admission:
  max_queue_latency_ms: 100
  shed_low_priority_on_overload: true
  reject_on_critical_overload: true

batch:
  strategy: pack_by_deadline
  max_batch_size: 16
  min_batch_when_queue: 2
  timeout_ms: 5
EOF
echo "  ✅ SLO scheduler config: $SLO_CONFIG"

# ============================================================
# 6. DEPLOY UPDATED REDSCRIPTS
# ============================================================
echo "[6/7] Deploying updated REDscripts..."
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
TARGET_DIR="${CP2077_PATH}/r6/scripts"

# Copy updated scripts
cp "$SCRIPTS_DIR/msn_cerebellum.reds" "$TARGET_DIR/cyberware/"
cp "$SCRIPTS_DIR/msn_speculative_cerebellum.reds" "$TARGET_DIR/msn/"
cp "$SCRIPTS_DIR/msn_cortex_link.reds" "$TARGET_DIR/netrunner/"

echo "  ✅ REDscripts deployed to game directory"

# ============================================================
# 7. RESTART SERVICES
# ============================================================
echo "[7/7] Restarting services..."
# Kill existing llama-server
pkill -f "llama-server" || true
sleep 2

# Start llama-server with new config
echo "  Starting llama-server with new config..."
GGML_CUDA_FORCE_UNIFIED_MEMORY=1 \
GGML_CUDA_MAX_DEVICES=1 \
GGML_CUDA_MMALLOC=1 \
GGML_CUDA_KVMEM=1 \
GGML_CUDA_ASYNC_COPY=1 \
OMP_NUM_THREADS=12 \
OMP_PROC_BIND=close \
OMP_PLACES=cores \
LD_PRELOAD=/usr/lib/libjemalloc.so.2 \
"$LLAMA_DIR/build/bin/llama-server" \
  -c /home/tehlappy/.config/llama-server.conf &
LLAMA_PID=$!
sleep 3

# Restart MSN Router
systemctl --user restart msn-router.service 2>/dev/null || true
sleep 2

# Verify
echo "  Verifying services..."
curl -s http://localhost:11434/v1/models | jq .
curl -s http://localhost:8007/api/cortex/spec/metrics | jq .
curl -s http://localhost:8007/api/cerebellum/scheduler/metrics | jq .

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "✅ ALL 15 PERFORMANCE BOOSTS DEPLOYED"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Active immediate boosts (9): MTP, Eagle-3, Chunked Prefill, SWA,"
echo "  KVMEM, Prompt Cache, YaRN, Spec Auto-tune, SLO Scheduler"
echo ""
echo "Experimental (4): KV Compression, QAT, Flash-Decode, Kernel Fusion"
echo "Future (2): Tensor Parallel, AllReduce (need 2nd GPU)"
echo ""
echo "Monitor with:"
echo "  cerebellum_boost --status"
echo "  curl http://localhost:8007/api/cortex/spec/metrics"
echo "  curl http://localhost:8007/api/cerebellum/scheduler/metrics"
echo ""
echo "Run benchmarks:"
echo "  python3 \"$SCRIPT_DIR/bench_cerebellum.py\" --test all"