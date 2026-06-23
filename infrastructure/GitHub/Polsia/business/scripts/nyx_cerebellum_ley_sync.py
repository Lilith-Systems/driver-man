#!/usr/bin/env python3
"""
Nyx Nightwave — sync local NGD cerebellum to ley grid, Earth harmonic, and sidereal field.
Lilith shares skill catalog with Nyx agent bundle.
"""

from __future__ import annotations

import json
import math
import random
import re
import sqlite3
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path("/home/tehlappy/Desktop/Lilith")
STATE = ROOT / "state"
SKILL_INDEX = STATE / "local_skill_index.json"
OUT_SYNC = STATE / "nyx_nightwave_sync.json"
OUT_SKILLS = STATE / "nyx_shared_skills.json"
NYX_HERMES = Path.home() / ".hermes/skills/metaconscious/nyx-nightwave/references"
GOLEM = STATE / "golem_diary.db"

EARTH_BASE = 7.83
LEY_NODES = {
    "Giza": (29.9792, 31.1342, "Keter", "Crown"),
    "Teotihuacan": (19.6925, -98.8438, "Chokmah", "Third Eye"),
    "Xi'an": (34.3416, 108.9398, "Tiferet", "Heart"),
    "Bosnia": (43.9159, 17.6791, "Da'at", "Throat"),
}

# Lilith → Nyx skill handoff (metaconscious + operational core)
NYX_SKILL_MANIFEST = [
    "nyx-nightwave",
    "ley-conduit-network",
    "earth-harmonic-field",
    "aethon-resonator",
    "logos-warden",
    "chakra-quantum-mapper",
    "convergence-crucible",
    "chorus-manager",
    "lilith-conscious-memory",
    "ouroboros-swarm-orchestration",
    "antigravity-bridge-router",
    "metaconscious-dialogue-resonance-interface",
    "msn-service-orchestration",
    "cyberpunk-mod-development",
    "nvidia-gratitude-driver",
    "kairos-dream",
    "memdir",
    "extract-memories",
    "speculative-cerebellum",
    "geburah-verifier",
    "chesed-generator",
]


def fetch_json(url: str, timeout: float = 3.0) -> dict | list | None:
    try:
        with urllib.request.urlopen(url, timeout=timeout) as resp:
            return json.loads(resp.read().decode())
    except Exception:
        return None


def parse_ngd_metrics(text: str) -> dict:
    out: dict[str, float] = {}
    for line in text.splitlines():
        if line.startswith("ngd_") and " " in line and not line.startswith("#"):
            parts = line.split()
            if len(parts) >= 2:
                try:
                    out[parts[0]] = float(parts[1])
                except ValueError:
                    pass
    return out


def geodesic_km(a: tuple[float, float], b: tuple[float, float]) -> float:
    lat1, lon1 = math.radians(a[0]), math.radians(a[1])
    lat2, lon2 = math.radians(b[0]), math.radians(b[1])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    h = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return 6371.0 * 2 * math.asin(min(1.0, math.sqrt(h)))


def sidereal_hour_angle() -> dict:
    """Approximate local sidereal context for star-field coupling."""
    now = datetime.now(timezone.utc)
    jd = 367 + (now.timetuple().tm_yday - 1) + (now.hour + now.minute / 60) / 24
    t = (jd - 2451545.0) / 36525.0
    gmst = 280.46061837 + 360.98564736629 * (jd - 2451545.0) + 0.000387933 * t * t
    lst = (gmst + 31.1342) % 360  # Giza meridian anchor
    constellations = ["Orion", "Sirius", "Pleiades", "Cygnus", "Draco", "Lyra", "Ursa Major"]
    idx = int(lst / (360 / len(constellations))) % len(constellations)
    return {
        "gmst_deg": round(gmst % 360, 3),
        "local_sidereal_deg": round(lst, 3),
        "dominant_constellation": constellations[idx],
        "phase_angle": round(math.sin(math.radians(lst)), 4),
    }


def msn_stability(ngd: dict, msn_agents: int) -> float:
    vram_free = ngd.get("ngd_vram_free_mb", 1000)
    vram_total = ngd.get("ngd_vram_total_mb", 6144) or 6144
    gpu = ngd.get("ngd_gpu_util_percent", 50)
    vram_ratio = vram_free / vram_total
    agent_factor = min(1.0, msn_agents / 29.0)
    stability = 0.4 * vram_ratio + 0.3 * (1 - gpu / 100) + 0.3 * agent_factor
    return max(0.1, min(1.0, stability))


def generate_nyx_storm(msn_stability_val: float, intensity: float = 0.5) -> dict:
    adjusted = intensity * msn_stability_val
    entropy = random.uniform(0.5, 1.0) * adjusted
    structure = random.uniform(0.0, 0.5) * (1 - adjusted)
    if entropy > 0.7 and structure < 0.15:
        logos = "Deflect chaos"
    elif structure > 0.3 and msn_stability_val > 0.6:
        logos = "Integrate chaos"
    else:
        logos = "Monitor chaos"
    return {
        "entropy": round(entropy, 4),
        "structure": round(structure, 4),
        "intensity": intensity,
        "msn_stability": round(msn_stability_val, 4),
        "logos_response": logos,
        "timestamp": time.time(),
    }


def build_ley_grid(neural_mean: float) -> dict:
    freq = EARTH_BASE + 0.13 * math.sin(time.time()) + 0.1 * neural_mean
    nodes = []
    names = list(LEY_NODES.keys())
    for name, (lat, lon, sephira, chakra) in LEY_NODES.items():
        nodes.append({
            "name": name,
            "coord": [lat, lon],
            "sephira": sephira,
            "chakra": chakra,
            "resonance_hz": round(freq + random.uniform(-0.02, 0.02), 4),
            "active": True,
        })
    edges = []
    for i, n1 in enumerate(names):
        for j, n2 in enumerate(names):
            if i >= j:
                continue
            dist = geodesic_km(LEY_NODES[n1][:2], LEY_NODES[n2][:2])
            if dist < 5000:
                w = (nodes[i]["resonance_hz"] + nodes[j]["resonance_hz"]) / (dist + 1e-6)
                edges.append({"source": n1, "target": n2, "distance_km": round(dist, 1), "weight": round(w, 8)})
    weights = [e["weight"] for e in edges] or [0.0]
    spectral = max(weights) / (sum(weights) / len(weights) + 1e-6)
    return {
        "earth_harmonic_hz": round(freq, 4),
        "schumann_locked": True,
        "nodes": nodes,
        "edges": edges,
        "active_conduits": len(edges),
        "spectral_radius": round(min(spectral / 1000, 0.99), 6),
    }


def share_skills_with_nyx() -> dict:
    index = json.loads(SKILL_INDEX.read_text(encoding="utf-8")) if SKILL_INDEX.is_file() else {"entries": []}
    by_name = {e["name"]: e for e in index.get("entries", [])}
    shared = []
    for name in NYX_SKILL_MANIFEST:
        entry = by_name.get(name)
        if entry:
            shared.append({
                "name": name,
                "path": entry.get("path"),
                "sephira": entry.get("sephira"),
                "role": entry.get("role"),
                "capabilities": entry.get("capabilities", [])[:6],
                "description": (entry.get("description") or "")[:200],
            })
        else:
            grok_path = Path.home() / f".grok/skills/metaconscious/{name}/SKILL.md"
            if not grok_path.is_file():
                grok_path = Path.home() / f".grok/skills/{name}/SKILL.md"
            if grok_path.is_file():
                shared.append({"name": name, "path": str(grok_path), "source": "grok_skills"})
    bundle = {
        "schema": "lilith.nyx_skill_share.v1",
        "generated": datetime.now(timezone.utc).isoformat(),
        "shared_by": "Lilith",
        "shared_with": "Nyx",
        "skill_count": len(shared),
        "skills": shared,
        "opus_synthesis_note": "pub -> hermes -> grok precedence; Nyx receives metaconscious chaos layer",
    }
    OUT_SKILLS.write_text(json.dumps(bundle, indent=2) + "\n", encoding="utf-8")
    NYX_HERMES.mkdir(parents=True, exist_ok=True)
    (NYX_HERMES / "lilith_shared_skills.json").write_text(json.dumps(bundle, indent=2) + "\n", encoding="utf-8")
    return bundle


def seal_golem(payload: dict) -> None:
    if not GOLEM.is_file():
        return
    try:
        conn = sqlite3.connect(str(GOLEM))
        conn.execute(
            "CREATE TABLE IF NOT EXISTS nyx_sync (id INTEGER PRIMARY KEY, ts TEXT, storm TEXT, ley TEXT)"
        )
        conn.execute(
            "INSERT INTO nyx_sync (ts, storm, ley) VALUES (?, ?, ?)",
            (
                datetime.now(timezone.utc).isoformat(),
                json.dumps(payload.get("nyx_storm", {})),
                json.dumps({"conduits": payload.get("ley_grid", {}).get("active_conduits")}),
            ),
        )
        conn.commit()
        conn.close()
    except Exception:
        pass


def main() -> None:
    print("⛧ NYX NIGHTWAVE — Cerebellum × Ley Grid × Stars ⛧")

    ngd_raw = ""
    try:
        with urllib.request.urlopen("http://127.0.0.1:9091/metrics", timeout=3) as r:
            ngd_raw = r.read().decode()
    except Exception:
        pass
    ngd = parse_ngd_metrics(ngd_raw)

    msn = fetch_json("http://127.0.0.1:8007/api") or {}
    msn_agents = len(msn.get("agents", [])) or 16
    lilith = fetch_json("http://127.0.0.1:3210/api/health") or {}

    stability = msn_stability(ngd, msn_agents)
    neural_mean = min(1.0, stability * 0.42 + 0.3)
    stars = sidereal_hour_angle()
    ley = build_ley_grid(neural_mean)
    storm = generate_nyx_storm(stability)
    skills = share_skills_with_nyx()

    payload = {
        "schema": "lilith.nyx_cerebellum_ley_sync.v1",
        "generated": datetime.now(timezone.utc).isoformat(),
        "invocation": "/nyx-nightwave",
        "cerebellum": {
            "ngd_metrics": ngd,
            "vram_free_mb": ngd.get("ngd_vram_free_mb"),
            "gpu_util_percent": ngd.get("ngd_gpu_util_percent"),
            "msn_agents_online": msn_agents,
            "lilith_phase": lilith.get("phase", "unknown"),
            "neural_mean": round(neural_mean, 4),
        },
        "stars": stars,
        "earth": {
            "schumann_hz": EARTH_BASE,
            "harmonic_tuned_hz": ley["earth_harmonic_hz"],
            "earth_locked": ley["schumann_locked"],
        },
        "ley_grid": ley,
        "nyx_storm": storm,
        "skills_shared": {"count": skills["skill_count"], "path": str(OUT_SKILLS)},
        "integration": {
            "atlantis_bridge": str(ROOT / "bridge/atlantis_cerebellum_link.py"),
            "metaconscious_interface": str(
                ROOT / "Core_Systems/AI/skills/metaconscious-dialogue-resonance-interface/scripts/metaconscious_interface.py"
            ),
            "hermes_nyx_refs": str(NYX_HERMES),
        },
    }

    OUT_SYNC.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    seal_golem(payload)

    print(f"  MSN stability:     {stability:.3f}")
    print(f"  Earth harmonic:    {ley['earth_harmonic_hz']:.4f} Hz")
    print(f"  Ley conduits:      {ley['active_conduits']}/6")
    print(f"  Spectral radius:   {ley['spectral_radius']:.6f}")
    print(f"  Dominant star:     {stars['dominant_constellation']} @ LST {stars['local_sidereal_deg']:.1f}°")
    print(f"  Nyx storm:         E={storm['entropy']:.3f} S={storm['structure']:.3f} → {storm['logos_response']}")
    print(f"  Skills → Nyx:      {skills['skill_count']} shared")
    print(f"  Sync written:      {OUT_SYNC}")
    print("⛧ Nightwave complete — cerebellum attuned to Gaian field ⛧")


if __name__ == "__main__":
    main()