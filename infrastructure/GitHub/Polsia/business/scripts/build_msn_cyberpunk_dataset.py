#!/usr/bin/env python3
"""Build SFT dataset for MSN Cyberpunk 2077 — mods, court, engine, console, skills."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path("/home/tehlappy/Desktop/Lilith")
CP2077 = ROOT / "Core_Systems/AI/abyssal-assets/cp2077_mods"
OUT = ROOT / "data/msn_cyberpunk_supplement.json"

SKIP_DIRS = {"output", "test_mod", "tools", ".git", "packed", "msn_magic_starwars_project", "__pycache__"}
MAX_FILE_BYTES = 80_000
MAX_CODE_SNIP = 6000

SEPHIRA_AGENTS = {
    "Keter": "Lucifer", "Chokmah": "Baal", "Binah": "Yeshua", "Chesed": "Thoth",
    "Gevurah": "Abraxas", "Tiferet": "Ouroboros", "Netzach": "Nyx",
    "Hod": "Hod", "Yesod": "Yesod", "Malkuth": "Malkuth",
}


def entry(prompt: str, response: str) -> dict:
    return {"conversations": [{"from": "human", "value": prompt}, {"from": "gpt", "value": response}]}


def load_json(path: Path) -> dict | list | None:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def scan_mod_files() -> list[dict]:
    rows: list[dict] = []
    if not CP2077.exists():
        return rows
    for path in sorted(CP2077.rglob("*")):
        if not path.is_file():
            continue
        if path.suffix not in {".reds", ".yaml", ".yml", ".toml", ".tweakdb"}:
            continue
        if any(p in SKIP_DIRS for p in path.relative_to(CP2077).parts):
            continue
        try:
            if path.stat().st_size > MAX_FILE_BYTES:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore").strip()
            if not text:
                continue
            rel = path.relative_to(CP2077).as_posix()
            lang = "redscript" if path.suffix == ".reds" else path.suffix.lstrip(".")
            snippet = text[:MAX_CODE_SNIP]
            if len(text) > MAX_CODE_SNIP:
                snippet += "\n// ... truncated for training ..."

            rows.append(entry(
                f"What does the MSN Cyberpunk mod file `{rel}` do and how does it integrate with the gaming engine?",
                (
                    f"`{rel}` is part of the Lilith MSN integration for Cyberpunk 2077. "
                    f"It routes through `msn_gaming_engine.reds` and `msn_gtc_sephirotic_router.reds` "
                    f"with central bootstrap hooks — no per-file @wrapMethod spam.\n\n"
                    f"```{lang}\n{snippet}\n```"
                ),
            ))

            # Symbol extraction for REDscript
            if path.suffix == ".reds":
                for m in re.finditer(r"public (?:final )?(?:static )?class (\w+)", text):
                    cls = m.group(1)
                    rows.append(entry(
                        f"What is `{cls}` in the MSN Cyberpunk mod stack?",
                        f"`{cls}` is defined in `{rel}`. It registers with LilithSovereignKernel "
                        f"and participates in the Sephirotic Court routing layer for GTC mods.",
                    ))
                for m in re.finditer(r'\[ConsoleCommand\("([^"]+)"', text):
                    cmd = m.group(1)
                    rows.append(entry(
                        f"What does the Cyberpunk console command `{cmd}` do in MSN mods?",
                        f"`{cmd}` is registered in `{rel}`. Run it in-game with REDmod enabled "
                        f"after loading a save. Part of the MSN/GTC integration console surface.",
                    ))
        except OSError:
            continue
    return rows


def court_registry_entries() -> list[dict]:
    rows: list[dict] = []
    reg = load_json(CP2077 / "output/sephirotic_court_registry.json")
    if not isinstance(reg, dict):
        return rows
    counts = reg.get("sephira_counts", {})
    for sephira, agent in SEPHIRA_AGENTS.items():
        n = counts.get(sephira, 0)
        rows.append(entry(
            f"Which Sephirotic Court agent handles {sephira} in MSN Cyberpunk?",
            f"{sephira} is routed to court agent **{agent}** via `msn_gtc_sephirotic_router.reds`. "
            f"{n} mod files are stamped and bound through `SephiroticCourtBinder.RegisterAll()`.",
        ))
    rows.append(entry(
        "How many files does the Sephirotic Court bind in Cyberpunk MSN?",
        f"The court binds **{reg.get('total_files', 0)}** files across 10 Sephirot. "
        f"Verify in-game: `msn.court.status` and `msn.gtc.shards`.",
    ))
    return rows


def skill_bridge_entries() -> list[dict]:
    rows: list[dict] = []
    bridge = load_json(ROOT / "state/cyberpunk_skill_bridge.json")
    if not isinstance(bridge, dict):
        return rows
    for item in bridge.get("entries", [])[:120]:
        if not isinstance(item, dict):
            continue
        name = item.get("skill_name") or item.get("name") or "unknown"
        cmds = item.get("cyberpunk_commands") or []
        desc = (item.get("description") or "")[:500]
        if cmds:
            rows.append(entry(
                f"Which MSN console commands map to skill `{name}` in Cyberpunk?",
                f"Skill `{name}` maps to: {', '.join(cmds)}. {desc}",
            ))
    return rows


def core_qa_entries() -> list[dict]:
    return [
        entry(
            "How does MSNGamingEngine bootstrap in Cyberpunk 2077?",
            "On `PlayerPuppet.OnGameAttached`, `MSNGamingEngine.BootstrapOnce()` runs once. "
            "It initializes MSNEnginePerformance, MSNMasterIntegration, MSNGTCSephiroticRouter, "
            "and SephiroticCourtBinder. Console: `msn.engine.status`.",
        ),
        entry(
            "What is the MSN performance tier system for Cyberpunk?",
            "MSNEnginePerformance supports LOW, BALANCED, HIGH tiers controlling NGD cooldown, "
            "learn batch cooldown, and player action sampling. Console: `msn.engine.perf low|balanced|high`.",
        ),
        entry(
            "How do GTC Aethon sync shards route without duplicate hooks?",
            "100 `gtc_aethon_sync_*` mods are stripped of per-mod @wrapMethod hooks. "
            "Events route through `MSNGTCSephiroticRouter.RouteDomain()` from the central engine. "
            "Console: `msn.gtc.shards`.",
        ),
        entry(
            "How do I deploy MSN mods to Cyberpunk 2077?",
            "Run `bash tools/complete_mods.sh` in cp2077_mods, then launch Steam with `-redmod`. "
            "First save load compiles `final.redscripts`. Verify: `msn.gtc.status`, `msn.court.status`.",
        ),
        entry(
            "What VRAM constraints apply when running MSN AI alongside Cyberpunk?",
            "RTX 3060 6GB: game needs ~3.5-4GB VRAM. MSN local cerebellum gets ~2GB. "
            "Use `msn-engine` or `grok-gtc-msn` with 4096 ctx, throttled NGD, and sampled player actions.",
        ),
        entry(
            "How does Lilith emergence work in MSN Cyberpunk mods?",
            "LilithSovereignKernel.NotifyEvent('lilith_emergence') triggers token sync, dialogue bridge, "
            "and crimson intensity. Console: `lilith.emerge` or `lilith.kernel`.",
        ),
        entry(
            "Write a REDscript EngineEvent call for combat in MSN mods.",
            "```redscript\nMSNGamingEngine.EngineEvent(n\"CombatHit\", \"player melee\", true);\n"
            "MSNGTCSephiroticRouter.GetInstance().OnCombat(\"melee_hit\");\n```",
        ),
        entry(
            "What console commands verify the full MSN Cyberpunk stack?",
            "`msn.gtc.status`, `msn.engine.status`, `msn.gtc.shards`, `msn.court.status`, "
            "`msn.symbiosis.sync`, `msn.tokens.sync`, `msn.dialogue.lilith`, `msn.ngd.status`, "
            "`msn.magic.status`, `msn.jedi.status`.",
        ),
    ]


def redmod_commands() -> list[dict]:
    rows: list[dict] = []
    toml = CP2077 / "redmod.toml"
    if not toml.exists():
        return rows
    text = toml.read_text(encoding="utf-8", errors="ignore")
    cmds = re.findall(r'"msn\.[^"]+"|"lilith\.[^"]+"|"gta\.[^"]+"|"abyssal\.[^"]+"', text)
    for raw in sorted(set(cmds))[:80]:
        cmd = raw.strip('"')
        rows.append(entry(
            f"Explain MSN mod console command `{cmd}`.",
            f"`{cmd}` is declared in `redmod.toml` for the msn_integration REDmod package. "
            f"Requires REDmod + redscript compile on first game load.",
        ))
    return rows


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    dataset: list[dict] = []
    dataset.extend(core_qa_entries())
    dataset.extend(court_registry_entries())
    dataset.extend(skill_bridge_entries())
    dataset.extend(redmod_commands())
    dataset.extend(scan_mod_files())

    # Dedupe by first user message
    seen: set[str] = set()
    unique: list[dict] = []
    for row in dataset:
        key = row["conversations"][0]["value"]
        if key in seen:
            continue
        seen.add(key)
        unique.append(row)

    OUT.write_text(json.dumps(unique, indent=2), encoding="utf-8")
    print(f"MSN Cyberpunk dataset: {len(unique)} entries → {OUT}")
    print(f"  Core QA: {len(core_qa_entries())}")
    print(f"  Mod files scanned from: {CP2077}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())