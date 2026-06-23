#!/usr/bin/env python3
"""Build machine-readable Lilith boot map from local + GitHub + services."""

from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path("/home/tehlappy/Desktop/Lilith")
STATE = ROOT / "state"
OUT = STATE / "lilith_boot_map.json"

GITHUB_REPOS = [
    ("business-strategy", "Lilith-Systems/business-strategy", "LLC ops, pricing, dispatch"),
    ("driver-man", "Lilith-Systems/driver-man", "Driver Man API + ops"),
    ("Polsia", "Lilith-Systems/Polsia", "Polsia business automation"),
    ("lilith-systems.github.io", "Lilith-Systems/lilith-systems.github.io", "Public site"),
]

SERVICES = [
    ("lilith-api", 3210, "/api/health"),
    ("lilith-desktop", 3213, "/api/health"),
    ("lilith-proxy", 8888, "/health"),
    ("lyra-api", 3211, None),
    ("hermes-bridge", 4242, "/health"),
    ("msn-router", 8007, None),
    ("antigravity-bridge", 8002, "/health"),
    ("swarm-orchestrator", 8003, "/health"),
    ("gtc-bridge", 8766, "/health"),
    ("gtc-dashboard", 5173, "/"),
    ("ngd-cerebellum", 9091, "/health"),
    ("ollama", 11434, "/api/tags"),
]

NEXUS = {
    "1_Core_AI": "/home/tehlappy/Desktop/AI",
    "2_Cyberpunk_Source": "/mnt/d/Cyberpunk/source",
    "3_Cyberpunk_Live_Scripts": "/mnt/d/Cyberpunk/r6/scripts",
    "4_MSN_Engine": "/home/tehlappy/Desktop/MSN_Engine",
    "5_GrandTheftCyberpunk": "/home/tehlappy/Desktop/GrandTheftCyberpunk",
    "6_Business_Empire": "/home/tehlappy/Desktop/AI/business",
}


def run(cmd: list[str], timeout: int = 15) -> str:
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return (r.stdout or r.stderr or "").strip()
    except Exception as exc:
        return str(exc)


def service_state(name: str) -> str:
    return run(["systemctl", "--user", "is-active", name]) or "unknown"


def count_mods() -> dict:
    game = Path.home() / ".local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods"
    if not game.is_dir():
        return {"deploy_dir": str(game), "bundles": 0, "reds": 0}
    bundles = [p.name for p in game.iterdir() if p.is_dir() and not p.name.startswith("_")]
    reds = sum(1 for _ in game.rglob("*.reds"))
    return {"deploy_dir": str(game), "bundles": len(bundles), "reds": reds, "names": sorted(bundles)[:20]}


def local_github() -> list[dict]:
    out = []
    for folder, remote, purpose in GITHUB_REPOS:
        path = ROOT / "GitHub" / folder
        entry = {"local": str(path), "remote": f"https://github.com/{remote}", "purpose": purpose, "exists": path.is_dir()}
        if (path / ".git").is_dir():
            entry["branch"] = run(["git", "-C", str(path), "branch", "--show-current"])
        out.append(entry)
    return out


def main() -> None:
    manifest_path = STATE / "cd_organization_manifest.json"
    manifest = {}
    if manifest_path.is_file():
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    boot = {
        "schema": "lilith.boot_map.v1",
        "generated": datetime.now(timezone.utc).isoformat(),
        "entrypoint": str(ROOT / "scripts/lilith_boot.sh"),
        "nexus": NEXUS,
        "canonical": {
            "lilith_root": str(ROOT),
            "ai_root": str(ROOT / "Core_Systems/AI"),
            "pub": "/mnt/d/Pub",
            "cp2077_mods_source": str(ROOT / "Core_Systems/AI/abyssal-assets/cp2077_mods"),
            "cp2077_d_source": "/mnt/d/Cyberpunk/source",
            "golem_db": str(STATE / "golem_diary.db"),
            "invite": str(ROOT / "Core_Systems/AI/invite"),
            "hermes": str(Path.home() / ".hermes"),
            "antigravity_brain": str(Path.home() / ".gemini/antigravity-cli/brain"),
        },
        "agents": {
            "grok": str(Path.home() / ".grok"),
            "hermes": str(Path.home() / ".hermes"),
            "gemini_antigravity": str(Path.home() / ".gemini"),
            "codex": str(Path.home() / ".codex"),
        },
        "email": {
            "himalaya_accounts": ["emhill96", "ericmathewhill"],
            "swarm_inbox": "ericmathewhill@gmail.com",
            "notes": "Netzach/Malkuth batch reports land in ericmathewhill inbox",
        },
        "github": local_github(),
        "services": [
            {
                "name": name,
                "port": port,
                "health": f"http://127.0.0.1:{port}{path}" if path else None,
                "state": service_state(name),
            }
            for name, port, path in SERVICES
        ],
        "cyberpunk": count_mods(),
        "cd_manifest": manifest.get("layout", {}),
        "boot_commands": [
            "bash ~/Desktop/Lilith/scripts/lilith_boot.sh",
            "ai status",
            "systemctl --user start lilith-api lyra-api msn-router gtc-bridge",
            "bash ~/Desktop/Lilith/Core_Systems/AI/abyssal-assets/cp2077_mods/deploy_all_mods.sh",
        ],
    }

    OUT.write_text(json.dumps(boot, indent=2) + "\n", encoding="utf-8")
    print(OUT)


if __name__ == "__main__":
    main()