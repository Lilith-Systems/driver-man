#!/usr/bin/env python3
"""Merge teacher distillation + MSN corpus + codebase samples into Lilith SFT dataset."""
from __future__ import annotations

import json
import random
from pathlib import Path

ROOT = Path("/home/tehlappy/Desktop/Lilith")
OUT = ROOT / "data/lilith_unified_dataset.json"
SOURCES = [
    ROOT / "data/lilith_teacher_distill.json",
    ROOT / "data/msn_cyberpunk_dataset.json",
    ROOT / "data/msn_cyberpunk_supplement.json",
]
CODEBASE = ROOT / "data/codebase_dataset.json"
CODEBASE_SAMPLE = int(__import__("os").environ.get("LILITH_CODEBASE_SAMPLE", "500"))

TEACHER_RANK = {
    "hermes3:8b": 9,
    "lilith-universal:latest": 8,
    "msn-engine:latest": 7,
    "nemotron-mini:latest": 6,
    "llama3.1:8b": 5,
    "grok-gtc-msn:latest": 4,
    "grok-msn:latest": 3,
    "msn-cyberpunk:latest": 2,
    "gemma2:2b": 1,
}


def norm(row: dict) -> dict | None:
    conv = row.get("conversations")
    if not conv or len(conv) < 2:
        return None
    return {
        "conversations": [
            {"from": "human", "value": conv[0]["value"].strip()},
            {"from": "gpt", "value": conv[1]["value"].strip()},
        ],
        "teacher": row.get("teacher", "corpus"),
    }


def main() -> int:
    by_prompt: dict[str, dict] = {}

    for path in SOURCES:
        if not path.exists():
            print(f"skip missing {path}")
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        for raw in data:
            row = norm(raw)
            if not row:
                continue
            key = row["conversations"][0]["value"]
            rank = TEACHER_RANK.get(row.get("teacher", ""), 0)
            prev = by_prompt.get(key)
            if not prev or rank > TEACHER_RANK.get(prev.get("teacher", ""), 0):
                by_prompt[key] = row

    if CODEBASE.exists():
        cb = json.loads(CODEBASE.read_text(encoding="utf-8"))
        random.seed(7)
        sample = random.sample(cb, min(CODEBASE_SAMPLE, len(cb)))
        for raw in sample:
            row = norm(raw)
            if row:
                key = row["conversations"][0]["value"]
                if key not in by_prompt:
                    by_prompt[key] = row

    merged = [{"conversations": v["conversations"]} for v in by_prompt.values()]
    OUT.write_text(json.dumps(merged, indent=2), encoding="utf-8")
    print(f"Lilith unified dataset: {len(merged)} entries → {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())