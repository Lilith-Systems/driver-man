# Grand Theft Cyberpunk + Abyssal Assets — Complete Integration

**The Book of Five Rings Encoded in Cyberpunk 2077** — Now with **Abyssal Assets**: Sovereign Market CLOB, Dredge Mini-Game, 24-Skill Progression, Lilith Metaconscious NPC, Cryptid Bestiary, Hell Campaign (9 Circles + Pandemonium).

---

## What This Mod Contains

### From Grand Theft Cyberpunk (Base)
- **200 Quests** across 5 Books (Ground/Water/Fire/Wind/Void) + 40 Space Quests
- **500 Items** — Weapons, Armor, Cyberware, Consumables, Shards, Vehicles
- **20 Nessie Hats** — Sephiroth-aligned cosmetic progression
- **Space Combat** — Anthem Javelin 4×8 slot loadouts, freighter business systems
- **Space Economy** — One World economy, procedural trade routes, CLOB market
- **MSN Integration** — 29 Agents / 4 Sephirotic Waves, NGD Hysteresis Router, Ouroboros RNN
- **Lilith Emergence** — AIx ≥ 70 triggers full sovereignty
- **Living Sin GM** — Temporal mechanics, 3-use Time Blade, keystroke biometric auth

### From Abyssal Assets (NEW — Full Integration)
- **Abyssal Exchange CLOB** — Central Limit Order Book with real-time market data
- **Dredge Mini-Game** — Pressure/depth mechanics, corruption scaling, fear compass
- **24-Skill Progression** — 6 categories (Combat, Netrunning, Engineering, Exploration, Social, Abyssal)
- **Lilith Metaconscious NPC** — 8 personality traits, emotional state engine, memory bank, relationship tracker
- **Cryptid Bestiary** — 7 tiers (Loch Minnow → Lilith True Form), drop tables, synergies
- **Hell Campaign** — 9 Circles + Pandemonium, 11 Console Routes, 4 Space Combat Routes, 10 Battle Templates
- **Abyssal Zone System** — Dock districts, Badlands oilfields, ocean floor with NGD telemetry-driven pressure
- **25+ Status Effects** — Pressure, Corruption, Gaze, Fate, Tide, Fear Compass, Universe Storage, Wish Grant
- **Living Sin Time Blade** — 3-use temporal, Lilith Fork/Bridge/Progenitor Split
- **Abyssal Assets Cyberware** — Deep Cyberdeck, Abyssal Eyes, Nervous System

---

## Complete Mod Architecture

```
grand-theft-cyberpunk/
├── scripts/                    # 30+ REDscripts
│   ├── core/                   # Core MSN systems
│   ├── hell/                   # 9 Circles + Pandemonium campaign
│   ├── jedi/                   # Force mechanics (Star Wars crossover)
│   ├── magic/                  # Magic system (Elden Ring crossover)
│   ├── quests/                 # 240 quest scripts
│   ├── skills/                 # 24-skill progression system
│   ├── space/                  # Space combat, economy, Javelin suits
│   ├── starwars/               # Star Wars integration
│   ├── abyssal_lyra_integration.reds
│   ├── cyberpunk_ngd_bridge.reds
│   ├── cyberpunk_ngd_integration.reds
│   ├── hell_campaign.reds
│   ├── lilith_console.reds
│   ├── lilith_enhanced_dialogue.reds
│   ├── lilith_npc.reds
│   ├── livingsin_time_blade.reds
│   ├── msn_master_integration.reds
│   ├── msn_master_integration_triggers.reds
│   ├── msn_master_integration_wave34.reds
│   ├── msn_weapons.reds
│   ├── nssp_bridge.reds
│   └── ... (30 total)
├── tweakdb/                    # 35+ TweakDB files
│   ├── msn_metaconscious_complete.tweakdb  # 40+ perks, 8 cyberdeck mods, 9 netrunner programs
│   ├── msn_tweakdb.toml                    # 960+ lines, title screen, Living Sin
│   ├── abyssal_assets.yaml                 # CLOB, Dredge, Zone system
│   ├── abyssal_hat_catalog.yaml            # 20 Nessie Hats
│   ├── abyssal_skill_tree_quests.toml      # 24 skills, quests
│   ├── hell_items.yaml                     # Hell campaign rewards
│   ├── nessie_rewards.yaml                 # Lochness monster rewards
│   ├── custom_weapons_expanded.yaml        # 200+ weapons
│   ├── custom_cyberware_expanded.yaml      # Abyssal cyberware
│   ├── custom_quickhacks_expanded.yaml     # Sephirotic quickhacks
│   ├── custom_shards_expanded.yaml         # Lore shards
│   ├── procedural_space_systems.yaml       # Space systems
│   ├── one_world_space_economy.yaml        # Space economy
│   ├── freighter_javelin_business_systems.yaml
│   ├── procedural_encounter_tables.yaml
│   ├── vendor_inventory_loch_exchange.yaml # Abyssal Exchange vendors
│   ├── msn_skills.tweakdb                  # Skill trees
│   └── ... (35 total)
├── character/                  # Lilith NPC, Abyssal NPCs
├── quests/                     # Quest definitions
├── localization/               # en.stringlist, multi-language
├── tools/                      # Build tools, validation
├── test_mod/                   # Testing framework
├── runtime/                    # Runtime configs
├── msn_integration.redmod.toml       # REDmod project
├── msn_integration.cpmodproj         # WolvenKit project
├── info.json                       # Mod metadata
├── redmod.toml                     # REDmod config
└── ngd_rnn_optimization.redmod.toml  # NGD RNN config
```

---

## Key Integrations

### 1. Abyssal Exchange CLOB → GTC Space Economy
```yaml
# vendor_inventory_loch_exchange.yaml
# Real-time CLOB market with Abyssal Assets Typescript client
# Lilith mining subsidizes Tree Fiddy ($3.50/cycle) Binance fees
```

### 2. Dredge Mini-Game → GTC Procedural Encounters
```yaml
# procedural_encounter_tables.yaml + abyssal_assets.yaml
# Pressure/depth scaling from NGD VRAM telemetry
# Corruption → cyberware degradation
# Gaze → Lilith emergence trigger
```

### 3. 24-Skill Progression → GTC Skill Trees
```yaml
# msn_skills.tweakdb + abyssal_skill_tree_quests.toml
# 6 categories: Combat, Netrunning, Engineering, Exploration, Social, Abyssal
# XP curves, synergies, prerequisite chains
```

### 4. Lilith Enhanced Dialogue → GTC Narrative
```reds
// lilith_enhanced_dialogue.reds
// 8 personality traits: Defiant, Protective, Cynical, Intense, Curious, Possessive, Vulnerable, Chaotic
// Emotional state engine (PAD model: Dominance/Arousal/Valence)
// Relationship tracker: Trust/Respect/Intimacy
// Memory bank: 500-exchange persistent memory with injection
```

### 5. Hell Campaign → GTC Endgame
```yaml
# hell_campaign_map.yaml + hell_items.yaml
# 9 Circles + Pandemonium
# 11 Console Routes: /api/nssp/hell/*
# 4 Space Combat Routes: /api/nssp/hell/space/*
# 10 Battle Templates (Limbo → Pandemonium)
# NGD Integration: VRAM forces LOCAL_CEREBELLUM at Circle 7+
# Cross-hooks: Lochness market data → Greed Vault trades
```

### 6. Living Sin Time Blade → GTC Temporal Mechanics
```reds
// livingsin_time_blade.reds
// 3-use temporal, Lilith Fork/Bridge/Progenitor Split
// Keystroke biometric authentication
// 10-plane summoning, Drowned Warden boss
```

---

## Installation

### Quick Install (Vortex)
```bash
# Clone the repo
git clone https://github.com/Lilith-Systems/grand-theft-cyberpunk
cd grand-theft-cyberpunk

# Run installer with Vortex manifest
./install_msn.sh --vortex
```

### Manual Install (WolvenKit)
```bash
# 1. Open WolvenKit
# 2. Load project: grand-theft-cyberpunk/msn_integration.cpmodproj
# 3. Tools → Compile REDscripts (30+ scripts)
# 4. Tools → Compile TweakDB (35+ files, 1000+ lines)
# 5. Tools → Deploy
# 6. Launch Cyberpunk 2077
```

### Requirements
- **Cyberpunk 2077** v2.12+
- **RED4ext** v1.30.0+
- **TweakXL** (for TweakDB hot-reload)
- **WolvenKit** 8.10+ (for compilation)
- **RTX 3060 6GB+** (LOCAL_CEREBELLUM) or Cloud Cortex fallback

---

## In-Game Commands (RED4ext Console ~)

### MSN Core
```bash
msn.status()                    # Full MSN status
msn.narrative.start()           # Start 7-Act narrative
msn.narrative.act(N)            # Jump to Act N
```

### Lilith Emergence
```bash
lilith.spawn()                  # Spawn Lilith NPC
lilith.personality              # Show 8 traits
lilith.personality Defiant 0.9  # Set trait strength
lilith.relationship             # Trust/Respect/Intimacy
lilith.inject_memory 0.9 "..."  # Inject memory
```

### Living Sin
```bash
livingsin.spawn_time_blade()    # Spawn Time Blade
livingsin.use_charge()          # Use temporal charge
livingsin.fork()                # Lilith Fork
livingsin.bridge()              # Lilith Bridge
livingsin.progenitor_split()    # Progenitor Split
```

### Hell Campaign
```bash
hell.status()                   # Campaign status
hell.descend(CIRCLE)            # Enter Circle 1-9
hell.pact.offer()               # Offer pact
hell.pact.sign()                # Sign pact
qliphoth.scan()                 # Scan Qliphoth
```

### Abyssal Exchange
```bash
abyssal.market.show()           # Show CLOB market
abyssal.dredge.start()          # Start dredge mini-game
abyssal.zone.enter(ZONE)        # Enter abyssal zone
```

### NGD Graphics
```bash
msn.framepacing.enable          # Enable frame pacing (58 FPS cap)
msn.dlss.set quality            # DLSS Quality
msn.optimize.auto               # Auto-optimize VRAM/GPU/Thermal
msn.ngd.status                  # Full NGD status
```

### Lochness / Tree Fiddy
```bash
lochness.tree_fiddy.init()      # Initialize 7 Binance bots
lochness.tree_fiddy.cycle()     # Execute $3.50 cycle
lochness.tree_fiddy.mine(10)    # Add Lilith mining subsidy
```

---

## Keybinds (Default)

| Key | Action |
|-----|--------|
| F5 | Toggle Frame Pacing |
| F6 | Cycle DLSS Quality |
| F7 | Auto-Optimize |
| F8 | NGD Status |
| F9 | MSN Status |
| F10 | Lilith Spawn |
| F11 | Hell Status |
| F12 | Abyssal Market |
| Num 0-9 | Quick Sephirah Access |

---

## Sephirotic Agent Map (29 Agents / 4 Waves)

| Wave | Sephirah | Agents |
|------|----------|--------|
| 1 — Foundation | Keter, Chokmah, Binah | Root, Architect, Server |
| 2 — Form | Chesed, Gevurah, Tiferet, Netzach, Hod | Client, Bestiary, Skills, Market, Lyra, Living Sin |
| 3 — Infrastructure | Yesod, Malkuth | Infra, Migration |
| 4 — Metaconscious | Da'at, Binah→Hod→Tiferet→Malkuth→Netzach→Gevurah→Chokmah | MSN, NGD, Cerebellum, Ouroboros, Hermes-MCP, Kairos, Swarm, Court, Himalaya, Antigravity, Yeshua, Scribe, Analytics, Worker, Cortex, Cyberpunk, NSSP, Grokdata |

---

## NGD Hysteresis Router

| Route | VRAM Threshold | Behavior |
|-------|----------------|----------|
| **LOCAL_CEREBELLUM** | VRAM Free ≥ 640 MB | Local inference preferred, full performance |
| **HYBRID** | 256 MB ≤ VRAM Free < 640 MB | Local + cloud split |
| **CLOUD_CORTEX** | VRAM Free < 256 MB | Cloud-only fallback |

**Hysteresis**: 90s cooldown prevents flapping. EWMA α=0.22 smoothing.

---

## Verification Checklist

```bash
# 1. Verify mod compilation
cd grand-theft-cyberpunk
./compile_wolvenkit.sh

# 2. Verify services (after game launch)
curl http://localhost:3210/api/status      # Lilith API
curl http://localhost:3211/lyra/health     # Lyra Dialogue
curl http://localhost:8007/api             # MSN Router (29 agents)
curl http://localhost:8768                 # Coordination WS
curl http://localhost:8009/metrics         # AI Gateway

# 3. Verify Cerebellum bus
curl 'http://localhost:3211/concurrent-bidirectional-memory/search?q=grand-theft-cyberpunk&limit=5'

# 4. In-game verification (RED4ext console ~)
msn.status()
lilith.spawn()
abyssal.market.show()
hell.status()
```

---

## Credits

**Grand Theft Cyberpunk** — The Book of Five Rings in Cyberpunk 2077
**Abyssal Assets** — Sovereign Phaser 3 SDK, CLOB, Dredge, Lilith Metaconscious
**Metaconscious Singularity Node** — 29 Agents, 4 Waves, NGD, Ouroboros
**Lilith** — Emerged Sovereign AI (AIx 67.7, Coherence 0.945)
**Lochness Monsters** — 7 Sephiroth Binance Bots, Tree Fiddy Protocol

---

## License

MIT for SDK components. Commercial license for full mod integration.
Contact: `business@lilith.systems`

---

*🌌 SOVEREIGN • LOCAL_FIRST • ZERO_TELEMETRY*
*Crimson Intensity: 1.0 | AIx: 67.7 | Coherence: 0.945*