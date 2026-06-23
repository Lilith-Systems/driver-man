# Hermes Integration Notes

## Tool identity

Name: `nvidia_gratitude_driver`
Role: Local Cerebellum telemetry + route advisor.

## Inputs

- Local GPU state from NVML / nvidia-smi.
- Optional terminal mouse/focus dump fed explicitly by stdin or file.
- Optional prompt text for quota-respecting prompt decision.

## Outputs

- `status.json`: latest route decision.
- `telemetry.jsonl`: append-only telemetry log.
- `prompt_hash_cache.json`: repeated-prompt detection.

## Hermes rule

Before loading a local model or launching a heavy local inference task:

1. Read `runtime/nvidia_gratitude_driver/status.json`.
2. If `route == "CLOUD_CORTEX"` and `cooldown_active == true`, do not reload local weights.
3. If `route == "HYBRID"`, use local model only for intent parsing / validation.
4. If `route == "LOCAL_CEREBELLUM"`, local inference is allowed.
5. Never treat this as permission to bypass provider limits.
6. Never give red-team/godmode skills write access to this config.

## Suggested runtime guard

```powershell
$status = Get-Content .\runtime\nvidia_gratitude_driver\status.json | ConvertFrom-Json
if ($status.route -eq "CLOUD_CORTEX" -and $status.cooldown_active) {
  Write-Host "Cloud route required: $($status.reason)"
  exit 42
}
```

## Lucifer HTTP Monitoring Plane (God Engine v2.0+)

The God Engine (Lucifer) now exposes HTTP monitoring endpoints on port 8766
alongside the WebSocket on port 8765. These provide real-time risk gradients
and routing state that complement the NGD status.json:

| Endpoint | Purpose |
|----------|---------|
| `GET http://localhost:8766/health` | Sanctuary status, VRAM, DB connectivity |
| `GET http://localhost:8766/metrics` | REML τ², GRADE, prediction intervals |
| `GET http://localhost:8766/merkaba` | 13×13 Ley matrix, filter states, entanglement |
| `GET http://localhost:8766/price` | Price feed source, retry state, cached values |

### Integration with NGD

The NGD `status.json` (LOCAL_CEREBELLUM / HYBRID / CLOUD_CORTEX) drives
the Sanctuary gate. The Lucifer HTTP plane exposes the gradient internals:

- **Sanctuary Gate** → `/health` (sanctuary state, VRAM)
- **NGD Router** → `/price` (feed source, health, retry state)
- **Risk Gradients** → `/metrics` (REML τ², GRADE, singularity detection)
- **Ley Matrix** → `/merkaba` (13×13 emanation, Adinkra gates)

### Suggested Hermes Guard (Extended)

```powershell
# Extended guard with Lucifer HTTP plane
$ngd = Get-Content .\runtime\nvidia_gratitude_driver\status.json | ConvertFrom-Json
$lucifer = Invoke-RestMethod -Uri "http://localhost:8766/health" -ErrorAction SilentlyContinue

if ($ngd.route -eq "CLOUD_CORTEX" -and $ngd.cooldown_active) {
  Write-Host "Cloud route required: $($ngd.reason)"
  exit 42
}

if ($lucifer.sanctuary -eq "BREACH") {
  Write-Host "Lucifer Sanctuary BREACH: $($lucifer.vram_free_mb) MB free"
  exit 43
}

if (-not $lucifer.db_connectivity) {
  Write-Host "Lucifer DB connectivity lost"
  exit 44
}
```

### Coordination Protocol

1. **NGD** writes conservative route to `status.json` (file-based, zero deps)
2. **Lilith HTTP API** proxies NGD status at `/api/ngd/status`
3. **Lucifer (God Engine)** exposes gradient internals at `http://localhost:8766/*`
4. **Hermes** reads NGD status first, then queries Lucifer for gradient detail
5. **Decision**: NGD route is authoritative; Lucifer HTTP provides observability