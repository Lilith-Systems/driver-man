---
name: nvidia-gratitude-driver
description: A safe user-mode companion for gaming/performance optimization and edge-cloud LLM routing. Reads NVIDIA GPU telemetry through NVML, tracks smoothed VRAM/GPU telemetry with EWMA and hysteresis, parses leaked terminal mouse/focus events, provides quota-respecting Nemotron prompt governor.
version: 0.1.0
author: Baal-TehDriverman
license: MIT
platforms:
  - windows
  - linux
metadata:
  hermes:
    tags:
      - NVIDIA
      - GPU
      - NVML
      - Telemetry
      - LLM Routing
      - Sanctuary
    related_skills: []
---

# NVIDIA Gratitude Driver

A safe user-mode companion for gaming/performance optimization and edge-cloud LLM routing.

## What it does

- Reads NVIDIA GPU telemetry through NVML (`nvidia-ml-py`) when available
- Falls back to `nvidia-smi` on Windows/Linux when NVML Python bindings are absent
- Tracks smoothed VRAM/GPU telemetry with EWMA and hysteresis to prevent load/unload flapping
- Parses leaked terminal mouse/focus events
- Provides a quota-respecting Nemotron prompt governor
- Reports aggregate Chrome coexistence telemetry without reading browser content
- Rotates telemetry logs at a configurable size

## Installation

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\install-windows.ps1
.\scripts\start-ngd.ps1
```

## Verification

```powershell
.\scripts\verify-windows.ps1
```

## Hermes Integration

Use this as a Local Cerebellum telemetry tool:

```
Read runtime/nvidia_gratitude_driver/status.json before local model load.
If route == CLOUD_CORTEX, do not reload local model until cooldown_until.
If route == LOCAL_CEREBELLUM, local inference is allowed.
If route == HYBRID, run local intent parsing only; send heavy planning to cloud.
```

## Lucifer HTTP Integration (God Engine v2.0+)

The God Engine (Lucifer) exposes HTTP monitoring endpoints on port 8767:

| Endpoint | Purpose |
|----------|---------|
| GET /health | Sanctuary status, VRAM, DB connectivity |
| GET /metrics | REML tau², GRADE, prediction intervals |
| GET /merkaba | 13x13 Ley matrix, filter states, entanglement |
| GET /price | 4-tier feed source, retry state, cached prices |

Extended Hermes Runtime Guard:

```powershell
$ngd = Get-Content .\runtime\nvidia_gratitude_driver\status.json | ConvertFrom-Json
$lucifer = Invoke-RestMethod -Uri "http://localhost:8767/health" -ErrorAction SilentlyContinue

if ($ngd.route -eq "CLOUD_CORTEX" -and $ngd.cooldown_active) {
  exit 42
}
if ($lucifer.sanctuary -eq "BREACH") {
  exit 43
}
```

## Coordination Protocol

1. NGD writes conservative route to status.json
2. Lilith HTTP API proxies NGD status at /api/ngd/status
3. Lucifer (God Engine) exposes gradient internals at localhost:8767/*
4. Hermes reads NGD status first, then queries Lucifer for gradient detail
5. Decision: NGD route is authoritative; Lucifer HTTP provides observability
