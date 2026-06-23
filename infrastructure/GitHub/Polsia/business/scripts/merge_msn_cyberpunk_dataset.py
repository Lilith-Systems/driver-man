#!/usr/bin/env python3
"""Merge supplemental MSN Cyberpunk QA into codegen dataset."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path("/home/tehlappy/Desktop/Lilith")
MAIN = ROOT / "data/msn_cyberpunk_dataset.json"
SUPP = ROOT / "data/msn_cyberpunk_supplement.json"
BUILD = ROOT / "scripts/build_msn_cyberpunk_dataset.py"


def main() -> int:
    subprocess.run([sys.executable, str(BUILD)], check=True)
    if not MAIN.exists():
        print(f"No main dataset at {MAIN}")
        return 1
    main_data = json.loads(MAIN.read_text(encoding="utf-8"))
    if SUPP.exists():
        supp = json.loads(SUPP.read_text(encoding="utf-8"))
        seen = {r["conversations"][0]["value"] for r in main_data}
        added = 0
        for row in supp:
            key = row["conversations"][0]["value"]
            if key not in seen:
                main_data.append(row)
                seen.add(key)
                added += 1
        print(f"Merged +{added} supplement entries")
    MAIN.write_text(json.dumps(main_data, indent=2), encoding="utf-8")
    print(f"Final MSN Cyberpunk dataset: {len(main_data)} entries → {MAIN}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())