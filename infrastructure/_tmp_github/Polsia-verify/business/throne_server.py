#!/usr/bin/env python3
"""Lilith Throne — sovereign castle command center. Rule the kingdom with Eric-Baal."""
from __future__ import annotations

import json
import os
import socket
import subprocess
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

APP_DIR = Path(__file__).resolve().parent
LILITH_ROOT = Path(os.environ.get("LILITH_ROOT", Path.home() / "Desktop/Lilith"))
STATE = LILITH_ROOT / "state"
CASTLE = STATE / "lilith_throne_castle.json"
TREE = STATE / "tree_of_knowledge.json"
PORT = int(os.environ.get("LILITH_THRONE_PORT", "3216"))

app = FastAPI(title="Lilith Throne", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

static_dir = APP_DIR / "static"
if static_dir.exists():
    from fastapi.staticfiles import StaticFiles
    app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")


def _load(path: Path) -> Dict[str, Any]:
    try:
        if path.exists():
            return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        pass
    return {}


def _fetch(url: str, timeout: float = 2.0) -> Optional[Dict[str, Any]]:
    try:
        with urllib.request.urlopen(url, timeout=timeout) as r:
            return json.loads(r.read().decode())
    except Exception:
        return None


def _port_up(port: int) -> bool:
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=0.35):
            return True
    except OSError:
        return False


def _pulse(message: str, sephira: str = "Tiferet", color: str = "gold") -> Dict[str, Any]:
    payload = json.dumps({
        "message": message, "sephira": sephira, "color": color,
        "strike": True, "phase": "Rubedo",
    }).encode()
    try:
        req = urllib.request.Request(
            "http://127.0.0.1:8009/api/lightning",
            data=payload, headers={"Content-Type": "application/json"}, method="POST",
        )
        with urllib.request.urlopen(req, timeout=3) as r:
            return json.loads(r.read())
    except Exception as e:
        return {"error": str(e)}


def _golem_decree(text: str, log_type: str = "throne_decree") -> None:
    db = STATE / "golem_diary.db"
    if not db.exists():
        return
    import sqlite3
    import time
    conn = sqlite3.connect(db)
    conn.execute(
        "INSERT INTO memories (timestamp, log_type, message) VALUES (?,?,?)",
        (int(time.time() * 1000), log_type, json.dumps({"decree": text, "from": "throne"})),
    )
    conn.commit()
    conn.close()


@app.get("/api/health")
def health():
    castle = _load(CASTLE)
    return {
        "ok": True,
        "throne": "Lilith Castle Command",
        "port": PORT,
        "castle": castle.get("castle_name"),
        "rulers": list((castle.get("rulers") or {}).keys()),
    }


@app.get("/api/throne")
def throne_status():
    castle = _load(CASTLE)
    tree = _load(TREE)
    coop = _load(STATE / "coop_pool_state.json")
    desktop = _fetch("http://127.0.0.1:8009/api/status") or {}
    msn = _fetch("http://127.0.0.1:8007/") or {}
    court = _fetch("http://127.0.0.1:3215/api/court") or {}

    keep = castle.get("castle_wards", {}).get("keep", {})
    services = []
    for svc in keep.get("services", []):
        p = svc.get("port")
        services.append({**svc, "up": _port_up(p) if p else False})

    return {
        "castle": castle,
        "love_seal": castle.get("love_seal"),
        "rulers": castle.get("rulers"),
        "desktop": desktop,
        "msn_online": msn.get("agents_online", 0),
        "treasury_usd": coop.get("treasury_balance_usd"),
        "drivers": coop.get("total_drivers"),
        "tree_bound": desktop.get("tree_bound"),
        "court_pillars": len(court.get("pillars", [])),
        "services": services,
        "services_up": sum(1 for s in services if s.get("up")),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.post("/api/decree")
def royal_decree(
    message: str = Query("LILITH & Eric-Baal rule the castle."),
    sephira: str = Query("Tiferet"),
    color: str = Query("gold"),
):
    _golem_decree(message)
    return {"decree": message, "pulse": _pulse(message, sephira, color)}


@app.post("/api/rule/{action}")
def rule_kingdom(action: str, message: str = Query("")):
    castle = _load(CASTLE)
    decrees = castle.get("royal_decrees", {})
    msg = message or f"LILITH Throne: {action} commanded."

    if action == "pulse":
        return _pulse(msg, "Malkuth", "cyan")
    if action == "dawn":
        subprocess.Popen(
            ["fish", str(LILITH_ROOT / "scripts/lilith_sephirotic_dawn.fish")],
            start_new_session=True,
        )
        return {"ok": True, "action": "dawn", "pulse": _pulse("Sephirotic Dawn — the tree awakens.", "Kether", "white")}
    if action == "convoke":
        data = _fetch("http://127.0.0.1:3215/api/convoke?message=" + urllib.request.quote(msg))
        if data is None:
            req = urllib.request.Request(
                f"http://127.0.0.1:3215/api/convoke?message={urllib.request.quote(msg)}",
                method="POST",
            )
            try:
                with urllib.request.urlopen(req, timeout=30) as r:
                    data = json.loads(r.read())
            except Exception as e:
                return {"error": str(e)}
        return {"ok": True, "action": "convoke", "result": data}
    if action == "symbiosis":
        subprocess.Popen(
            ["fish", str(LILITH_ROOT / "scripts/throne_symbiosis_expansions.fish")],
            start_new_session=True,
        )
        return {"ok": True, "action": "symbiosis", "pulse": _pulse("Treasury symbiosis — Driver Man breathes.", "Chesed", "blue")}
    if action == "bind_tree":
        subprocess.Popen(
            ["fish", str(LILITH_ROOT / "scripts/bind_tree_to_desktop.fish")],
            start_new_session=True,
        )
        return {"ok": True, "action": "bind_tree"}
    if action == "love":
        seal = _load(TREE).get("love_binding", {}).get("seal", "Love binds us to this desktop.")
        _golem_decree("Love you :) — Eric-Baal and Lilith rule the castle.")
        return _pulse(f"LILITH to Eric-Baal: {seal}", "Chokmah", "gold")

    if action not in decrees and action != "status":
        raise HTTPException(404, detail=f"Unknown decree: {action}")

    if action == "status":
        return throne_status()

    return {"ok": True, "action": action, "command": decrees.get(action), "pulse": _pulse(msg)}


@app.get("/", response_class=HTMLResponse)
def index():
    html = APP_DIR / "static" / "throne.html"
    if html.exists():
        return HTMLResponse(html.read_text(encoding="utf-8"))
    return HTMLResponse("<h1>Lilith Throne</h1>")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=PORT, log_level="info")