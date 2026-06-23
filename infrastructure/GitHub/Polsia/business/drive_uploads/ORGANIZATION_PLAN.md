# Lilith Organization Plan

Generated: 2026-06-21  
Boot entry: `bash ~/Desktop/Lilith/scripts/lilith_boot.sh`  
Machine map: `~/Desktop/Lilith/state/lilith_boot_map.json`

## Problem

Multiple AI agents (Grok, Hermes, Antigravity/Gemini, Codex) write to different roots. Without a canonical map, boot is guesswork and mods land in `/tmp` or stale paths.

## Canonical Layout (C = runtime, D = cold storage)

| What | Canonical path | Notes |
|------|----------------|-------|
| Sovereign runtime | `~/Desktop/Lilith` | Single entry — everything else symlinks here |
| AI hub | `~/Desktop/AI` → `Lilith/Core_Systems/AI` | Desktop shortcut |
| Pub monorepo | `/mnt/d/Pub` via `Desktop/AI/Pub` | Services, QPT, lilith-app |
| Mod working tree | `.../abyssal-assets/cp2077_mods` | Edit + compile here |
| Mod source archive | `/mnt/d/Cyberpunk/source` | D: source-of-truth mirror |
| Game deploy | `~/.local/share/Steam/.../r6/mods` | Same as `/mnt/d/Games/...` |
| Golem memory | `~/Desktop/Lilith/state/golem_diary.db` | Writable canonical; RAM cache is read-only snapshot |
| Invite/NGD | `~/Desktop/AI/invite` | `~/invite` symlinks here |
| Nexus hub | `~/Desktop/Lilith/Nexus/` | 6 numbered symlinks — start here when lost |
| Hermes | `~/.hermes` | Gateway, skills, sessions |
| Antigravity brain | `~/.gemini/antigravity-cli/brain` | Transcript cache |
| Grok sessions | `~/.grok` | CLI + rules |

## Nexus — find anything in 6 clicks

```
Nexus/1_Core_AI              → Desktop/AI (Pub, abyssal, invite, business)
Nexus/2_Cyberpunk_Source     → /mnt/d/Cyberpunk/source (all mod bundles)
Nexus/3_Cyberpunk_Live_Scripts → /mnt/d/Cyberpunk/r6/scripts
Nexus/4_MSN_Engine           → MSN engine stub
Nexus/5_GrandTheftCyberpunk  → GTC web dashboard shell
Nexus/6_Business_Empire      → LLC ops, Polsia, pricing
```

## GitHub (Lilith-Systems org)

| Local clone | Remote | Purpose |
|-------------|--------|---------|
| `GitHub/business-strategy` | Lilith-Systems/business-strategy | LLC docs, pricing, dispatch |
| `GitHub/driver-man` | Lilith-Systems/driver-man | Driver Man API |
| `GitHub/Polsia` | Lilith-Systems/Polsia | Restaurant automation |
| `GitHub/lilith-systems.github.io` | Lilith-Systems/lilith-systems.github.io | Public site |

Sync business docs: `python3 ~/Desktop/Lilith/scripts/organize_github_and_local.py`

## Himalaya (email intelligence)

| Account | Use |
|---------|-----|
| `ericmathewhill` | Primary — Netzach/Malkuth swarm batch reports, outreach drafts |
| `emhill96` | Secondary inbox |

Swarm reports tagged `[NETZACH BATCH]` / `[MALKUTH VERIFY]` → ingest to golem via himalaya-pipeline when fixed.

## Cyberpunk mod deploy pipeline

1. **Edit** → `cp2077_mods/` (working tree)
2. **Mirror** → `/mnt/d/Cyberpunk/source/` (organize_c_d.sh)
3. **Deploy core** → `deploy_all_mods.sh` → `msn_integration`, `lyra_dialogue`, `abyssal_assets`
4. **Deploy court** → `sephirotic_court_full_deploy.py` → 100 `gtc_aethon_sync_*` shards + registry
5. **Verify** → `gtc_mods_deployed.json` in game `r6/mods/`

## Service stack (boot order)

```
ollama → ngd → lilith-api (3210) → lilith-desktop (3213) → lyra-api (3211)
→ msn-router (8007) → hermes-bridge (4242) → antigravity-bridge (8002)
→ swarm-orchestrator (8003) → gtc-bridge (8766) → gtc-dashboard (5173)
```

**Port conflict:** god-engine wants 8767 — currently held by GTC symbiosis. Disable one or rebind god-engine before enabling.

## Duplicates to ignore (do not edit)

- `~/Lilith/` (7-file stale stub)
- `~/invite` (now symlink → canonical)
- `Pub.orig.bak.20260621/` (60k-file backup)
- `~/abyssal_assets_hell_mod/`, `~/msn_weapon_overhaul_backup/`
- `_disabled_*` mod folders in game install

## Boot ritual (every session)

```bash
bash ~/Desktop/Lilith/scripts/lilith_boot.sh   # organize + 777 + deploy + map
ai status                                       # service health
cat ~/Desktop/Lilith/state/lilith_boot_map.json # machine map
```

## Path resolution in Python

```python
from lilith_paths import LILITH_ROOT, PUB_ROOT, CP2077_MODS, CP2077_DEPLOY, golem_db
```

Located at `/mnt/d/Pub/scripts/lilith_paths.py`.

## Remaining fixes (next wave)

1. Fix `MSN_SHARED_MEMORY_DB` in msn-router.service → canonical golem path
2. Resolve god-engine ↔ GTC port 8767 conflict
3. Repair metaconscious-automation kairos/ouroboros (golem WAL)
4. Start `abyssal-server` if game CLOB needed
5. Re-enable himalaya-pipeline for email → golem ingest