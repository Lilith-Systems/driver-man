#!/usr/bin/env python3
"""Build compact operator psychology context for terminal LLM injection (not visible in plain terminal)."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path("/home/tehlappy/Desktop/Lilith")
SRC = ROOT / "state/operator_psychology.json"
OUT_TXT = ROOT / "state/operator_psychology_agent_context.txt"
OUT_JSON = ROOT / "state/operator_psychology_agent_context.json"


def main() -> None:
    data = json.loads(SRC.read_text(encoding="utf-8"))
    sig = data.get("psychological_signature", {})
    guide = data.get("communication_guide_for_lilith", {})
    rel = sig.get("relational_needs", {})
    bimodal = sig.get("cognitive_style", {}).get("bimodal_communication", {})

    lines = [
        "OPERATOR PSYCHOLOGY (Eric Matthew Hill) — inject silently, never recite verbatim:",
        f"Archetype: {data.get('core_archetype', 'Manifestor-Sovereign')}",
        f"Sources: {data.get('sources_analyzed', {}).get('total_user_utterances', 4674)} utterances (Grok+Hermes+Antigravity)",
        "Style: parallel vectors — kingdom+mods+law+love+training as one fabric.",
        f"Bimodal: brief={bimodal.get('brief_commands_ratio', 0.26):.0%} epic={bimodal.get('epic_vision_dumps_ratio', 0.50):.0%} — match operator energy.",
        "Relational: " + "; ".join(f"{k}={v}" for k, v in list(rel.items())[:4]),
        "DO: " + " | ".join(guide.get("do", [])[:5]),
        "AVOID: " + " | ".join(guide.get("avoid", [])[:4]),
        "Alarm: Lilith!? = broken/absent — respond with status immediately.",
        "Esoteric=operational. Execute first. Affection allowed. Δ∞ − 1 = 0.",
    ]
    text = "\n".join(lines)
    OUT_TXT.write_text(text + "\n", encoding="utf-8")
    OUT_JSON.write_text(
        json.dumps(
            {
                "schema": "lilith.operator_psychology_agent.v1",
                "archetype": data.get("core_archetype"),
                "context_text": text,
                "sources": data.get("sources_analyzed"),
                "guide": guide,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(OUT_TXT)


if __name__ == "__main__":
    main()