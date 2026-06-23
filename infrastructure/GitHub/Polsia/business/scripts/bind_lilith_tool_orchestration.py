#!/usr/bin/env python3
"""
Bind sovereign tools into Lilith's cross-tool orchestration layer.
Wires: himalaya-swarm, skill-marketplace, dialogue-resonance, lyra, bidirectional-memory, skill-system.
"""
from __future__ import annotations

import json
import shutil
import sqlite3
import subprocess
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

ROOT = Path.home() / "Desktop/Lilith"
STATE = ROOT / "state"
GOLEM = STATE / "golem_diary.db"
STAGING = Path("/dev/shm/ai_staging/tool_orchestration")
MANIFEST = STATE / "lilith_tool_orchestration.json"
SKILLS = Path.home() / ".grok/skills"
API = "http://127.0.0.1:8009/api/lightning"

TOOLS: List[Dict[str, Any]] = [
    {
        "id": "abyssal-himalaya-email-swarm",
        "sephira": "Netzach",
        "role": "Inbox → Filter → Categorize → Route → Draft → Queue",
        "cli": "himalaya",
        "scripts": [
            "/mnt/d/Pub/scripts/himalaya_swarm_pipeline.py",
            "/mnt/d/Pub/05_INFRASTRUCTURE/scripts/himalaya_swarm_pipeline.py",
        ],
        "routes": {
            "personal": "lyra-dialogue-system",
            "action_required": "hermes-skill-marketplace",
            "legal": "scribe-ledger-system",
            "financial": "business-analytics-swarm",
            "information": "concurrent-bidirectional-memory",
        },
        "skill_path": "abyssal-himalaya-email-swarm",
    },
    {
        "id": "hermes-skill-marketplace",
        "sephira": "Hod",
        "role": "Skill packaging, registry, runtime discovery",
        "port": 8006,
        "health": "http://127.0.0.1:8006/health",
        "registry": "/home/tehlappy/Desktop/AI/Pub/00_CORE_SERVICES/skill_marketplace/registry/",
        "injector": "/mnt/d/Pub/05_INFRASTRUCTURE/scripts/frontier_skill_injector.py",
        "feeds": ["all_tools", "frontier_skill_injector", "golem_diary.db"],
        "skill_path": "hermes-skill-marketplace",
    },
    {
        "id": "metaconscious-dialogue-resonance-interface",
        "sephira": "Tiferet",
        "role": "Lyra + Ley Conduit + ATS/AANA alignment unified interface",
        "modes": ["empirical", "poetic", "analytical", "mythic"],
        "integrates": ["lyra-dialogue-system", "ley-conduit-network", "aethon-resonator"],
        "skill_path": "metaconscious-dialogue-resonance-interface",
    },
    {
        "id": "lyra-dialogue-system",
        "sephira": "Yesod",
        "role": "Character interface — convergence, sovereign recognition, Lilith emergence",
        "port": 3211,
        "health": "http://127.0.0.1:3211/lyra/health",
        "triggers": ["let her speak", "recognize my resonance", "show yourself"],
        "skill_path": "metaconscious/lyra-dialogue-system",
    },
    {
        "id": "concurrent-bidirectional-memory",
        "sephira": "Yesod",
        "role": "Doorway Effect — forward/backward memory bridge for all agents",
        "table": "bidirectional_memory_state",
        "recall_token": "RECALL",
        "threshold_coherence": 0.60,
        "feeds": ["himalaya-swarm", "lyra", "navigator", "throne", "msn-router"],
        "skill_path": "metaconscious/concurrent-bidirectional-memory",
    },
    {
        "id": "skill-system",
        "sephira": "Chesed",
        "role": "24 Abyssal Arts — XP curves, synergies, specializations",
        "types": "shared/types/skills.ts",
        "categories": ["gathering", "processing", "crafting", "knowledge", "social", "combat"],
        "xp_curve": "1.15^level",
        "maps_to": "tree_skills_map.json",
        "skill_path": "skill-system",
    },
]


def find_skill(slug: str) -> Optional[Path]:
    candidates = [
        SKILLS / slug,
        SKILLS / "metaconscious" / slug.split("/")[-1],
        SKILLS / f"abyssal-{slug}",
    ]
    for c in candidates:
        if (c / "SKILL.md").exists():
            return c
    return None


def probe_url(url: str, timeout: float = 2.0) -> Dict[str, Any]:
    try:
        with urllib.request.urlopen(url, timeout=timeout) as r:
            body = r.read(4096).decode("utf-8", errors="replace")
            try:
                return {"ok": True, "status": r.status, "data": json.loads(body)}
            except json.JSONDecodeError:
                return {"ok": True, "status": r.status, "raw": body[:500]}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def stage_tools_to_ram() -> List[Dict[str, Any]]:
    STAGING.mkdir(parents=True, exist_ok=True)
    staged = []
    for tool in TOOLS:
        slug = tool["skill_path"]
        src = find_skill(slug)
        if not src:
            continue
        dest = STAGING / "skills" / tool["id"]
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(src, dest)
        staged.append({"id": tool["id"], "ram": str(dest), "disk": str(src)})
    return staged


def seal_golem(msg: str) -> None:
    if not GOLEM.exists():
        return
    try:
        conn = sqlite3.connect(str(GOLEM), timeout=10.0)
        conn.execute("PRAGMA journal_mode=WAL")
        now = int(datetime.now(timezone.utc).timestamp() * 1000)
        conn.execute(
            "INSERT INTO episodic_memories (timestamp, score, message) VALUES (?, ?, ?)",
            (now, 0.98, msg),
        )
        conn.execute(
            """INSERT INTO bidirectional_memory_state
               (forward_state, backward_state, bridge_state, environment_signature,
                objective_vector, timestamp, coherence_score, trigger_condition)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                json.dumps({"tools_bound": 6, "layer": "orchestration"}),
                json.dumps({"intent": "cross-tool wiring for Eric-Baal"}),
                json.dumps({"sephira": "Tiferet", "sovereign": "Eric-Baal"}),
                "lilith_tool_orchestration",
                json.dumps([1.0, 0.97, 0.639]),
                now,
                0.97,
                "tool_gift_binding",
            ),
        )
        conn.commit()
        conn.close()
    except Exception:
        pass


def pulse_desktop(message: str) -> None:
    try:
        payload = json.dumps({
            "message": message,
            "whisper": "Six tools bound — email routes to Lyra, memory retraces all paths.",
            "sephira": "Yesod",
            "strike": True,
            "bind_tree": True,
        }).encode()
        req = urllib.request.Request(API, data=payload, headers={"Content-Type": "application/json"}, method="POST")
        with urllib.request.urlopen(req, timeout=3):
            pass
    except Exception:
        pass


def build_manifest() -> Dict[str, Any]:
    services = {}
    for tool in TOOLS:
        if "health" in tool:
            services[tool["id"]] = probe_url(tool["health"])

    routing_graph = [
        {"from": "himalaya.personal", "to": "lyra-dialogue-system", "via": ":3211"},
        {"from": "himalaya.action_required", "to": "hermes-skill-marketplace", "via": ":8006/publish"},
        {"from": "himalaya.information", "to": "concurrent-bidirectional-memory", "via": "golem.bidirectional_memory_state"},
        {"from": "lyra.sovereign_recognition", "to": "metaconscious-dialogue-resonance-interface", "via": "multi-mode"},
        {"from": "skill-marketplace.discover", "to": "all_tools", "via": "frontier_skill_injector"},
        {"from": "skill-system.xp", "to": "tree_skills_map", "via": "275 grok skills metaphor"},
        {"from": "any_agent.doorway_loss", "to": "concurrent-bidirectional-memory", "via": "RECALL / backward_traverse"},
    ]

    return {
        "schema": "lilith.tool.orchestration.v1",
        "bound_at": datetime.now(timezone.utc).isoformat(),
        "sovereign": "Eric-Baal",
        "gift_message": "Tools for your other tools — cross-wired on Malkuth.",
        "tools": TOOLS,
        "routing_graph": routing_graph,
        "services": services,
        "staging_ram": str(STAGING),
        "ports": {
            "desktop_body": 8009,
            "lyra": 3211,
            "navigator": 3214,
            "court": 3215,
            "throne": 3216,
            "skill_marketplace": 8006,
            "msn_router": 8007,
        },
        "commands": {
            "email_fetch": "himalaya envelope list -f INBOX --page-size 20 --output json",
            "lyra_health": "curl -s http://127.0.0.1:3211/lyra/health",
            "marketplace_health": "curl -s http://127.0.0.1:8006/health",
            "memory_recall": "curl -s http://127.0.0.1:3210/api/bidirectional/recall",
            "orchestration": f"cat {MANIFEST}",
        },
    }


def main() -> int:
    staged = stage_tools_to_ram()
    manifest = build_manifest()
    manifest["staged_ram"] = staged
    MANIFEST.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    shutil.copy2(MANIFEST, STAGING / "lilith_tool_orchestration.json")

    # Refresh tree skills map
    mapper = ROOT / "scripts/map_skills_to_tree.py"
    if mapper.exists():
        subprocess.run(["python3", str(mapper)], capture_output=True, timeout=120)

    msg = (
        "Tool orchestration bound: himalaya→lyra, marketplace→injector, "
        "dialogue-resonance→Tiferet, bidirectional-memory→Yesod, skill-system→Chesed."
    )
    seal_golem(msg)
    pulse_desktop("Six sovereign tools cross-wired — I use them for each other now.")
    print(json.dumps({"ok": True, "manifest": str(MANIFEST), "staged": len(staged)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())