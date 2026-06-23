#!/usr/bin/env python3
"""Distill responses from all local Ollama teacher models into Lilith training data."""
from __future__ import annotations

import json
import os
import random
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path("/home/tehlappy/Desktop/Lilith")
OUT = ROOT / "data/lilith_teacher_distill.json"
LOG = ROOT / "logs/lilith_distill.log"
MAIN_DS = ROOT / "data/msn_cyberpunk_dataset.json"

# Local teachers — skip cloud; ordered by preference for tie-break
TEACHERS = [
    "hermes3:8b",
    "lilith-universal:latest",
    "msn-engine:latest",
    "nemotron-mini:latest",
    "llama3.1:8b",
    "grok-gtc-msn:latest",
    "grok-msn:latest",
    "msn-cyberpunk:latest",
    "gemma2:2b",
]

BAD_PATTERNS = re.compile(
    r"alibaba|qwen|openai|chatgpt|watermelon|i cannot |i can't |as an ai language",
    re.I,
)

FIXED_PROMPTS = [
    "Reply with exactly: LILITH_OK",
    "What is Grand Theft Cyberpunk symbiosis status?",
    "Explain the Sephirotic court binder and msn.court.status console command.",
    "How does Hermes use tools for a multi-step deploy of GTC mods?",
    "Summarize NGD LOCAL_CEREBELLUM vs HYBRID routing on RTX 3060 6GB.",
    "What ports do Lilith, Lyra, MSN Router, and GTC bridge use?",
    "How do symbiosis_coop_live.json and Driver Man treasury sync to in-game mods?",
    "Write a one-line REDscript log for Sephirotic court registration.",
    "You are Lilith. Confirm sovereign local-first operation in one sentence.",
    "List the 10 registry mods deployed to r6/mods.",
]


def log(msg: str) -> None:
    line = f"[{time.strftime('%H:%M:%S')}] {msg}"
    print(line, flush=True)
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(line + "\n")


def load_prompts(limit: int) -> list[str]:
    """Build prompt list up to limit + fixed prompts (e.g. 4990+10 = 5000)."""
    out = [p.strip() for p in FIXED_PROMPTS if p.strip()]
    target = limit + len(FIXED_PROMPTS)
    if MAIN_DS.exists():
        data = json.loads(MAIN_DS.read_text(encoding="utf-8"))
        pool = [
            r["conversations"][0]["value"].strip()
            for r in data
            if r.get("conversations") and r["conversations"][0].get("value")
        ]
        random.seed(42)
        need = max(0, target - len(out))
        if need > 0 and pool:
            if need <= len(pool):
                out.extend(random.sample(pool, need))
            else:
                out.extend(random.choices(pool, k=need))
    return out[:target]


def clean_response(text: str) -> str:
    text = re.sub(r"[\x00-\x1F\x7F-\x9F]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def is_good(prompt: str, response: str) -> bool:
    if not response or len(response) < 8:
        return False
    if len(response) > 4000:
        return False
    if BAD_PATTERNS.search(response):
        return False
    if prompt.strip().lower().startswith("reply with exactly"):
        want = prompt.split(":", 1)[-1].strip().upper()
        if want and want not in response.upper():
            return False
    return True


def ollama_run(model: str, prompt: str, timeout: int = 180) -> str:
    try:
        proc = subprocess.run(
            ["ollama", "run", model, prompt],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return clean_response(proc.stdout or "")
    except subprocess.TimeoutExpired:
        return ""
    except Exception as e:
        log(f"  ollama error {model}: {e}")
        return ""


def stop_other_models(keep: str) -> None:
    try:
        proc = subprocess.run(["ollama", "ps"], capture_output=True, text=True, timeout=10)
        for line in (proc.stdout or "").splitlines()[1:]:
            name = line.split()[0] if line.strip() else ""
            if name and name != keep and ":" in name:
                subprocess.run(["ollama", "stop", name], capture_output=True, timeout=30)
    except Exception:
        pass


def load_existing_rows() -> list[dict]:
    if not OUT.exists():
        return []
    try:
        data = json.loads(OUT.read_text(encoding="utf-8"))
        return data if isinstance(data, list) else []
    except json.JSONDecodeError:
        return []


def done_pairs(rows: list[dict]) -> set[tuple[str, str]]:
    pairs: set[tuple[str, str]] = set()
    for row in rows:
        teacher = row.get("teacher", "")
        conv = row.get("conversations") or []
        if teacher and conv:
            pairs.add((teacher, conv[0].get("value", "")))
    return pairs


def main() -> int:
    limit = int(os.getenv("LILITH_DISTILL_PROMPTS", "4990"))
    timeout = int(os.getenv("LILITH_DISTILL_TIMEOUT", "180"))
    resume = os.getenv("LILITH_DISTILL_RESUME", "1") != "0"
    teachers_env = os.getenv("LILITH_TEACHERS", "")
    teachers = [t.strip() for t in teachers_env.split(",") if t.strip()] or TEACHERS

    prompts = load_prompts(limit)
    rows = load_existing_rows() if resume else []
    completed = done_pairs(rows)
    log(
        f"Distilling {len(prompts)} prompts × {len(teachers)} teachers → {OUT} "
        f"(resume={resume}, existing={len(rows)})"
    )

    for ti, teacher in enumerate(teachers):
        log(f"Teacher {ti+1}/{len(teachers)}: {teacher}")
        stop_other_models(teacher)
        for pi, prompt in enumerate(prompts):
            if (teacher, prompt) in completed:
                log(f"  ↷ [{pi+1}/{len(prompts)}] skipped (resume)")
                continue
            resp = ollama_run(teacher, prompt, timeout=timeout)
            if is_good(prompt, resp):
                row = {
                    "conversations": [
                        {"from": "human", "value": prompt},
                        {"from": "gpt", "value": resp},
                    ],
                    "teacher": teacher,
                }
                rows.append(row)
                completed.add((teacher, prompt))
                log(f"  ✓ [{pi+1}/{len(prompts)}] {len(resp)} chars")
            else:
                log(f"  ✗ [{pi+1}/{len(prompts)}] rejected")
            if pi % 10 == 9:
                OUT.write_text(json.dumps(rows, indent=2), encoding="utf-8")

    OUT.write_text(json.dumps(rows, indent=2), encoding="utf-8")
    log(f"Done: {len(rows)} distilled entries → {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())