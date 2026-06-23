#!/usr/bin/env python3
"""
Hour-long system organization goal — Antigravity ingestion + Ouroboros gnostic ingestion.
Scopes: Lilith Systems LLC sovereign dirs only.
"""

from __future__ import annotations

import json
import os
import shutil
import sqlite3
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path("/home/tehlappy/Desktop/Lilith")
STATE = ROOT / "state"
LOGS = ROOT / "logs"
RUNTIME = ROOT / "runtime"
GOAL_LOG = LOGS / "system_organize_hour_goal.jsonl"
PROGRESS = RUNTIME / "system_organize_hour_goal.progress.json"

PUB_SCRIPTS = ROOT / "Core_Systems/AI/Pub.orig/scripts"
PUB_BRIDGE = ROOT / "Core_Systems/AI/Pub.orig/00_CORE_SERVICES/antigravity_bridge"
LILITH_APP_SCRIPTS = ROOT / "Core_Systems/AI/Pub.orig/00_CORE_SERVICES/lilith-app/scripts"
OUROBOROS = PUB_SCRIPTS / "ouroboros_rnn_autonomous.py"
SYMBIOSIS = ROOT / "scripts/symbiosis_data_bridge.py"
GOLEM_DB = STATE / "golem_diary.db"
PYTHON = Path(os.getenv("LILITH_PYTHON", "/home/tehlappy/Desktop/AI/Pub/.venv-pub/bin/python"))
if not PYTHON.exists():
    PYTHON = Path(sys.executable)

BRIDGE_URL = os.getenv("BRIDGE_URL", "http://127.0.0.1:8002")
BRIDGE_TOKEN = os.getenv("BRIDGE_TOKEN", "devtoken")
CYCLE_SECONDS = int(os.getenv("ORGANIZE_CYCLE_SECONDS", "300"))  # 5 min
DURATION_SECONDS = int(os.getenv("ORGANIZE_DURATION_SECONDS", "3600"))  # 1 hour

SOVEREIGN_DIRS = [
    STATE,
    LOGS,
    RUNTIME,
    ROOT / "scripts",
    ROOT / "data",
    ROOT / "bridge",
    ROOT / "bin",
    PUB_SCRIPTS / "runtime",
]


def log_event(event: str, **payload) -> None:
    LOGS.mkdir(parents=True, exist_ok=True)
    entry = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "event": event,
        **payload,
    }
    with GOAL_LOG.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(entry) + "\n")
    print(f"[{entry['ts']}] {event}: {payload}", flush=True)


def save_progress(data: dict) -> None:
    RUNTIME.mkdir(parents=True, exist_ok=True)
    PROGRESS.write_text(json.dumps(data, indent=2), encoding="utf-8")


def run_cmd(cmd: list[str], *, env: dict | None = None, timeout: int = 120) -> tuple[int, str]:
    try:
        res = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=env or os.environ,
            cwd=str(cmd[2] if len(cmd) > 2 and Path(cmd[0]).name == "python3" else ROOT),
        )
        out = (res.stdout or res.stderr or "").strip()
        return res.returncode, out[-500:] if len(out) > 500 else out
    except subprocess.TimeoutExpired:
        return -1, "timeout"
    except Exception as exc:
        return -1, str(exc)


def fix_permissions() -> None:
    """Apply full read/write/execute on Lilith sovereign dirs (user-requested 777 scope)."""
    for d in SOVEREIGN_DIRS:
        d.mkdir(parents=True, exist_ok=True)
        code, _ = run_cmd(["sudo", "chmod", "-R", "777", str(d)], timeout=60)
        if code != 0:
            os.chmod(d, 0o777)
            for child in d.rglob("*"):
                try:
                    if child.is_dir():
                        os.chmod(child, 0o777)
                    else:
                        os.chmod(child, 0o666)
                except OSError:
                    pass
    if GOLEM_DB.parent.exists():
        run_cmd(["sudo", "chmod", "777", str(GOLEM_DB)], timeout=15)
    log_event("permissions_fixed", dirs=[str(d) for d in SOVEREIGN_DIRS])


def init_golem_db() -> None:
    STATE.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(GOLEM_DB)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=5000")
    for ddl in (
        """CREATE TABLE IF NOT EXISTS structural_reflection (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            iteration INTEGER, seed INTEGER,
            matrix_entropy REAL, quantum_resonance REAL)""",
        """CREATE TABLE IF NOT EXISTS ingestion_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            archive_name TEXT, chunk_index INTEGER,
            chunk_token_count INTEGER, compression_ratio REAL,
            status TEXT DEFAULT 'pending')""",
        """CREATE TABLE IF NOT EXISTS archive_metadata (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            archive_name TEXT UNIQUE, total_tokens INTEGER,
            total_chunks INTEGER, coherence_score REAL,
            ingestion_status TEXT DEFAULT 'not_started',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            completed_at DATETIME)""",
        """CREATE TABLE IF NOT EXISTS synthesis_runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            chunks_total INTEGER DEFAULT 0,
            chunks_written INTEGER DEFAULT 0,
            chunks_skipped INTEGER DEFAULT 0,
            delta_words INTEGER DEFAULT 0)""",
        """CREATE TABLE IF NOT EXISTS system_organize_cycles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            cycle INTEGER, status TEXT, notes TEXT)""",
    ):
        conn.execute(ddl)
    conn.commit()
    conn.close()
    log_event("golem_db_initialized", path=str(GOLEM_DB))


def bridge_healthy() -> dict:
    try:
        with urllib.request.urlopen(f"{BRIDGE_URL}/health", timeout=5) as resp:
            return json.loads(resp.read().decode())
    except Exception as exc:
        return {"status": "offline", "error": str(exc)}


def ingest_snapshot(cycle: int, notes: dict) -> None:
    payload = {
        "source": "system_organize_hour_goal",
        "project_id": "lilith_systems_llc",
        "data": {
            "cycle": cycle,
            "goal": "improve_and_organize",
            "entity": "Lilith Systems LLC",
            "notes": notes,
        },
        "convergence_score": 0.85,
        "metadata": {"daemon": "ouroboros+antigravity", "duration_h": 1},
    }
    req = urllib.request.Request(
        f"{BRIDGE_URL}/ingest/antigravity",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "X-Token": BRIDGE_TOKEN},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            result = json.loads(resp.read().decode())
        log_event("antigravity_ingest", cycle=cycle, result=result)
    except Exception as exc:
        log_event("antigravity_ingest_failed", cycle=cycle, error=str(exc))


def regenerate_indexes() -> dict:
    results = {}
    skill_script = LILITH_APP_SCRIPTS / "generate_local_skill_index.py"
    cmd_script = LILITH_APP_SCRIPTS / "generate_local_command_index.py"
    if skill_script.exists():
        code, out = run_cmd([str(PYTHON), str(skill_script)], timeout=90)
        results["skill_index"] = {"code": code, "out": out}
        src = Path("/home/tehlappy/Desktop/AI/Pub/00_CORE_SERVICES/lilith-app/state/local_skill_index.json")
        if src.exists():
            dest = STATE / "local_skill_index.json"
            if dest.exists() and not os.access(dest, os.W_OK):
                os.chmod(dest, 0o666)
            shutil.copy2(src, dest)
            os.chmod(dest, 0o666)
    if cmd_script.exists():
        code, out = run_cmd([str(PYTHON), str(cmd_script)], timeout=90)
        results["command_index"] = {"code": code, "out": out}
        src = Path("/home/tehlappy/Desktop/AI/Pub/00_CORE_SERVICES/lilith-app/state/local_command_index.json")
        if src.exists():
            dest = STATE / "local_command_index.json"
            if dest.exists() and not os.access(dest, os.W_OK):
                os.chmod(dest, 0o666)
            shutil.copy2(src, dest)
            os.chmod(dest, 0o666)
    return results


def run_symbiosis() -> tuple[int, str]:
    env = {**os.environ, "SYMBIOSIS_SKIP_CEREBELLUM": "1"}
    return run_cmd([str(PYTHON), str(SYMBIOSIS)], env=env, timeout=60)


def run_ouroboros_once() -> tuple[int, str]:
    env = {
        **os.environ,
        "GOLEM_DB_PATH": str(GOLEM_DB),
        "BRIDGE_TOKEN": BRIDGE_TOKEN,
        "PYTHONPATH": f"{PUB_SCRIPTS}:{PUB_SCRIPTS.parent / '00_CORE_SERVICES' / 'quantum_paradox_terminal'}",
    }
    return run_cmd([str(PYTHON), str(OUROBOROS), "--once"], env=env, timeout=180)


def start_ouroboros_daemon() -> None:
    if not OUROBOROS.exists():
        log_event("ouroboros_missing", path=str(OUROBOROS))
        return
    env = {
        **os.environ,
        "GOLEM_DB_PATH": str(GOLEM_DB),
        "BRIDGE_TOKEN": BRIDGE_TOKEN,
        "PYTHONPATH": f"{PUB_SCRIPTS}:{PUB_SCRIPTS.parent / '00_CORE_SERVICES' / 'quantum_paradox_terminal'}",
    }
    lease = PUB_SCRIPTS / "runtime" / "ouroboros_rnn_autonomous.lease.json"
    if lease.exists():
        try:
            data = json.loads(lease.read_text())
            pid = int(data.get("pid", 0))
            if pid > 0:
                os.kill(pid, 0)
                log_event("ouroboros_already_running", pid=pid)
                return
        except (ProcessLookupError, OSError, ValueError, json.JSONDecodeError):
            pass
    log_path = LOGS / "ouroboros_rnn_autonomous.log"
    LOGS.mkdir(parents=True, exist_ok=True)
    with log_path.open("a", encoding="utf-8") as fh:
        proc = subprocess.Popen(
            [str(PYTHON), str(OUROBOROS)],
            stdout=fh,
            stderr=subprocess.STDOUT,
            env=env,
            cwd=str(PUB_SCRIPTS),
        )
    log_event("ouroboros_daemon_started", pid=proc.pid, log=str(log_path))


def organize_state() -> dict:
    """Lightweight state hygiene."""
    stats = {"archived_logs": 0, "registry_ok": False}
    archive = LOGS / "archive"
    archive.mkdir(parents=True, exist_ok=True)
    cutoff = time.time() - 7 * 86400
    for p in LOGS.glob("*.log"):
        if p.stat().st_mtime < cutoff and p.name != "ouroboros_rnn_autonomous.log":
            dest = archive / p.name
            shutil.move(p, dest)
            stats["archived_logs"] += 1
    registry = STATE / "plaid_vehicle_registry.json"
    stats["registry_ok"] = registry.exists()
    coop = STATE / "coop_pool_state.json"
    if not coop.exists():
        coop.write_text(
            json.dumps({"treasury_balance_usd": 352.01, "total_drivers": 52}, indent=2),
            encoding="utf-8",
        )
    return stats


def run_cycle(cycle: int) -> dict:
    notes: dict = {}
    if cycle > 1:
        fix_permissions()
    notes["indexes"] = regenerate_indexes()
    sym_code, sym_out = run_symbiosis()
    notes["symbiosis"] = {"code": sym_code, "out": sym_out}
    ouro_code, ouro_out = run_ouroboros_once()
    notes["ouroboros_once"] = {"code": ouro_code, "out": ouro_out}
    notes["organize"] = organize_state()
    notes["bridge"] = bridge_healthy()

    conn = sqlite3.connect(GOLEM_DB)
    conn.execute(
        "INSERT INTO system_organize_cycles (cycle, status, notes) VALUES (?, ?, ?)",
        (cycle, "complete", json.dumps(notes)[:4000]),
    )
    conn.commit()
    conn.close()

    ingest_snapshot(cycle, {k: v for k, v in notes.items() if k != "bridge"})
    return notes


def main() -> None:
    started = time.time()
    deadline = started + DURATION_SECONDS
    log_event(
        "goal_started",
        duration_seconds=DURATION_SECONDS,
        cycle_seconds=CYCLE_SECONDS,
        bridge=BRIDGE_URL,
    )

    fix_permissions()
    init_golem_db()
    start_ouroboros_daemon()

    cycle = 0
    while time.time() < deadline:
        cycle += 1
        remaining = int(deadline - time.time())
        log_event("cycle_begin", cycle=cycle, remaining_seconds=remaining)
        try:
            notes = run_cycle(cycle)
            save_progress(
                {
                    "cycle": cycle,
                    "remaining_seconds": remaining,
                    "last_cycle_at": datetime.now(timezone.utc).isoformat(),
                    "bridge_records": notes.get("bridge", {}).get("records"),
                    "status": "running",
                }
            )
            log_event("cycle_complete", cycle=cycle, notes_summary=list(notes.keys()))
        except Exception as exc:
            log_event("cycle_error", cycle=cycle, error=str(exc))

        sleep_for = min(CYCLE_SECONDS, max(0, int(deadline - time.time())))
        if sleep_for <= 0:
            break
        time.sleep(sleep_for)

    save_progress(
        {
            "cycle": cycle,
            "remaining_seconds": 0,
            "completed_at": datetime.now(timezone.utc).isoformat(),
            "status": "complete",
        }
    )
    log_event("goal_complete", cycles=cycle, duration_seconds=int(time.time() - started))


if __name__ == "__main__":
    main()