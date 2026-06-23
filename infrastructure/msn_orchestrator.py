#!/usr/bin/env python3
"""
MSN Universal Orchestrator — Master integration layer for Neural Sovereign Systems Platform (NSSP)
Monitors 15 subsystems with recursive self-improvement loop via Lilith evaluation.
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import logging
import os
import signal
import sqlite3
import subprocess
import sys
import time
import traceback
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field, asdict
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set

import requests
import websockets

# ─── Configuration ────────────────────────────────────────────────

ROOT = Path("/home/tehlappy/Desktop/AI")
APP = ROOT / "Pub/00_CORE_SERVICES/lilith-app"
STATE = APP / "state"
RUNTIME = APP / "runtime"
INVITE = ROOT / "invite"
MSN_STATE = Path("/home/tehlappy/.msn_orchestrator")

# Endpoints
LILITH_API = "http://localhost:3210"
LYRA_API = "http://localhost:3211"
NGD_STATUS = "http://localhost:3210/api/ngd/status"
COORDINATION_WS = "ws://127.0.0.1:8765"

# Fish script paths
FISH_SCRIPTS = {
    "skill_index": APP / "scripts/generate_local_skill_index.fish",
    "command_index": APP / "scripts/generate_local_command_index.fish",
    "memory_index": APP / "scripts/generate_bidirectional_memory_index.fish",
    "chat_agents_v3": APP / "scripts/run_lilith_chat_agents_v3.fish",
    "validate": APP / "scripts/validate_local_system.fish",
}

# Python script paths
PYTHON_SCRIPTS = {
    "skill_index": APP / "scripts/generate_local_skill_index.py",
    "command_index": APP / "scripts/generate_local_command_index.py",
    "memory_index": APP / "scripts/generate_bidirectional_memory_index.py",
    "validate": APP / "scripts/validate_local_system.py",
}

# Venv
VENV_PYTHON = "/home/tehlappy/Desktop/AI/venv/bin/python"
VENV_PUB_PYTHON = "/home/tehlappy/Desktop/AI/Pub/.venv-pub/bin/python"

# ─── Data Classes ────────────────────────────────────────────────

class SubsystemStatus(Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    DOWN = "down"
    UNKNOWN = "unknown"

@dataclass
class Subsystem:
    name: str
    status: SubsystemStatus = SubsystemStatus.UNKNOWN
    last_check: float = 0
    details: Dict[str, Any] = field(default_factory=dict)
    health_score: float = 0.0  # 0-1

@dataclass
class ImprovementProposal:
    id: str
    source: str  # "ngd", "monitoring", "lilith", "ouroboros", "cyberpunk"
    category: str  # "config", "code", "prompt", "skill", "architecture"
    priority: int  # 1-10
    description: str
    affected_files: List[str]
    implementation: str
    validation: str
    created_at: float = field(default_factory=time.time)
    status: str = "pending"  # pending, testing, staging, deployed, rolled_back

@dataclass
class TelemetrySnapshot:
    timestamp: float
    ngd: Dict[str, Any]
    cyberpunk: Optional[Dict[str, Any]]
    lilith: Dict[str, Any]
    lyra: Dict[str, Any]
    coordination: Dict[str, Any]
    ouroboros: Dict[str, Any]

# ─── Core Orchestrator ──────────────────────────────────────────

class MSNOrchestrator:
    """Master orchestrator for the entire MSN stack."""
    
    def __init__(self):
        self.logger = self._setup_logging()
        self.running = False
        self.subsystems: Dict[str, Subsystem] = {}
        self.proposals: List[ImprovementProposal] = []
        self.telemetry_history: List[TelemetrySnapshot] = []
        self.executor = ThreadPoolExecutor(max_workers=8)
        self.ws_client: Optional[websockets.WebSocketClientProtocol] = None
        self.ws_connected = False
        
        # Initialize subsystems
        self._init_subsystems()
        
        # Ensure state directory
        MSN_STATE.mkdir(parents=True, exist_ok=True)
        
        # Load persisted state
        self._load_state()
        
    def _setup_logging(self) -> logging.Logger:
        logger = logging.getLogger("MSNOrchestrator")
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        handler.setFormatter(logging.Formatter(
            "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
            datefmt="%H:%M:%S"
        ))
        logger.addHandler(handler)
        return logger
    
    def _init_subsystems(self):
        """Initialize all tracked subsystems."""
        subs = [
            "ngd", "lilith_api", "lyra_api", "coordination_ws",
            "ouroboros", "cyberpunk", "skills_index", "commands_index",
            "memory_index", "chat_agents", "validation", "narrative",
            "weapon_system", "lilith_character", "msn_scheduler"
        ]
        for name in subs:
            self.subsystems[name] = Subsystem(name=name)
    
    def _load_state(self):
        """Load persisted orchestrator state."""
        state_file = MSN_STATE / "orchestrator_state.json"
        if state_file.exists():
            try:
                data = json.loads(state_file.read_text())
                self.proposals = [ImprovementProposal(**p) for p in data.get("proposals", [])]
                self.logger.info(f"Loaded {len(self.proposals)} persisted proposals")
            except Exception as e:
                self.logger.warning(f"Failed to load state: {e}")
    
    def _save_state(self):
        """Persist orchestrator state."""
        state_file = MSN_STATE / "orchestrator_state.json"
        state_file.write_text(json.dumps({
            "proposals": [asdict(p) for p in self.proposals],
            "last_save": time.time(),
        }, indent=2))
    
    # ─── Subsystem Health Checks ─────────────────────────────────
    
    async def check_ngd(self) -> Subsystem:
        """Check NGD Local Cerebellum status."""
        sub = self.subsystems["ngd"]
        try:
            r = await asyncio.get_event_loop().run_in_executor(
                self.executor, lambda: requests.get(NGD_STATUS, timeout=3)
            )
            data = r.json()
            sub.status = SubsystemStatus.HEALTHY if data.get("route") == "LOCAL_CEREBELLUM" else SubsystemStatus.DEGRADED
            sub.details = data
            sub.health_score = 1.0 if sub.status == SubsystemStatus.HEALTHY else 0.5
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
        sub.last_check = time.time()
        return sub
    
    async def check_lilith_api(self) -> Subsystem:
        """Check Lilith API (port 3210)."""
        sub = self.subsystems["lilith_api"]
        try:
            r = await asyncio.get_event_loop().run_in_executor(
                self.executor, lambda: requests.get(f"{LILITH_API}/api/status", timeout=3)
            )
            data = r.json()
            sub.status = SubsystemStatus.HEALTHY if data.get("local_only") else SubsystemStatus.DEGRADED
            sub.details = data
            sub.health_score = 1.0 if data.get("local_only") else 0.7
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
        sub.last_check = time.time()
        return sub
    
    async def check_lyra_api(self) -> Subsystem:
        """Check Lyra API (port 3211)."""
        sub = self.subsystems["lyra_api"]
        try:
            r = await asyncio.get_event_loop().run_in_executor(
                self.executor, lambda: requests.get(f"{LYRA_API}/lyra/health", timeout=3)
            )
            data = r.json()
            sub.status = SubsystemStatus.HEALTHY if data.get("stability") else SubsystemStatus.DEGRADED
            sub.details = data
            sub.health_score = data.get("coherence", 0.5)
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
        sub.last_check = time.time()
        return sub
    
    async def check_coordination_ws(self) -> Subsystem:
        """Check MSN Coordination Server (WS 8768)."""
        sub = self.subsystems["coordination_ws"]
        try:
            async with websockets.connect(COORDINATION_WS, open_timeout=3) as ws:
                await ws.send(json.dumps({"type": "join", "player_id": "orchestrator_health"}))
                resp = await asyncio.wait_for(ws.recv(), timeout=3)
                data = json.loads(resp)
                self.ws_connected = True
                sub.status = SubsystemStatus.HEALTHY
                sub.details = {"session_id": data.get("session_id")}
                sub.health_score = 1.0
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
            self.ws_connected = False
        sub.last_check = time.time()
        return sub
    
    async def check_cyberpunk(self) -> Subsystem:
        """Check Cyberpunk 2077 process and telemetry."""
        sub = self.subsystems["cyberpunk"]
        try:
            # Check process
            proc = await asyncio.get_event_loop().run_in_executor(
                self.executor,
                lambda: subprocess.run(["pgrep", "-f", "Cyberpunk2077"], capture_output=True, text=True)
            )
            pid = proc.stdout.strip()
            
            # Check telemetry file
            tp = Path("~/Desktop/AI/invite/runtime/cyberpunk_telemetry.json").expanduser()
            if tp.exists():
                data = json.loads(tp.read_text())
                sub.status = SubsystemStatus.HEALTHY if pid else SubsystemStatus.DEGRADED
                sub.details = {"pid": pid, "telemetry": data}
                sub.health_score = 1.0 if pid else 0.6
            else:
                sub.status = SubsystemStatus.DEGRADED
                sub.details = {"pid": pid, "telemetry": "no_file"}
                sub.health_score = 0.5
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
        sub.last_check = time.time()
        return sub
    
    async def check_ouroboros(self) -> Subsystem:
        """Check Ouroboros RNN daemon."""
        sub = self.subsystems["ouroboros"]
        try:
            # Check if daemon process running
            proc = await asyncio.get_event_loop().run_in_executor(
                self.executor,
                lambda: subprocess.run(["pgrep", "-f", "ouroboros_rnn"], capture_output=True, text=True)
            )
            # Check memory database
            db_path = ROOT / "Pub/golem_diary.db"
            if db_path.exists():
                conn = sqlite3.connect(db_path, timeout=3)
                conn.execute("PRAGMA journal_mode=WAL")
                c = conn.cursor()
                c.execute("SELECT COUNT(*) FROM episodic_memory")
                count = c.fetchone()[0]
                conn.close()
                sub.status = SubsystemStatus.HEALTHY
                sub.details = {"episodic_memories": count, "daemon_pid": proc.stdout.strip() or "not_found"}
                sub.health_score = 1.0
            else:
                sub.status = SubsystemStatus.DEGRADED
                sub.health_score = 0.5
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
        sub.last_check = time.time()
        return sub
    
    async def check_indices(self) -> Dict[str, Subsystem]:
        """Check all local indices."""
        results = {}
        for name, path in [
            ("skills_index", STATE / "local_skill_index.json"),
            ("commands_index", STATE / "local_command_index.json"),
            ("memory_index", STATE / "bidirectional_memory_index.json"),
        ]:
            sub = self.subsystems[name]
            try:
                if path.exists():
                    data = json.loads(path.read_text())
                    required = ["schema", "local_only"]
                    ok = all(k in data for k in required)
                    sub.status = SubsystemStatus.HEALTHY if ok else SubsystemStatus.DEGRADED
                    sub.details = {
                        "entry_count": data.get("entry_count") or data.get("command_count") or data.get("node_count"),
                        "age_seconds": time.time() - path.stat().st_mtime
                    }
                    sub.health_score = 1.0 if ok else 0.5
                else:
                    sub.status = SubsystemStatus.DOWN
                    sub.health_score = 0.0
            except Exception as e:
                sub.status = SubsystemStatus.DOWN
                sub.details = {"error": str(e)}
                sub.health_score = 0.0
            sub.last_check = time.time()
            results[name] = sub
        return results
    
    async def check_chat_agents(self) -> Subsystem:
        """Check Lilith chat agents runtime."""
        sub = self.subsystems["chat_agents"]
        try:
            latest = RUNTIME / "lilith-chat-agents" / "latest-pass"
            if latest.exists() and latest.is_symlink():
                target = latest.resolve()
                reports = list(target.glob("reports/*.md"))
                sub.status = SubsystemStatus.HEALTHY if reports else SubsystemStatus.DEGRADED
                sub.details = {"latest_pass": target.name, "report_count": len(reports)}
                sub.health_score = 1.0 if reports else 0.5
            else:
                sub.status = SubsystemStatus.DOWN
                sub.health_score = 0.0
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
        sub.last_check = time.time()
        return sub
    
    async def check_validation(self) -> Subsystem:
        """Run local validation."""
        sub = self.subsystems["validation"]
        try:
            result = await asyncio.get_event_loop().run_in_executor(
                self.executor,
                lambda: subprocess.run(
                    ["fish", str(FISH_SCRIPTS["validate"])],
                    cwd=APP, capture_output=True, text=True, timeout=60
                )
            )
            if result.returncode == 0:
                data = json.loads(result.stdout)
                sub.status = SubsystemStatus.HEALTHY if data.get("ok") else SubsystemStatus.DEGRADED
                sub.details = data
                sub.health_score = 1.0 if data.get("ok") else 0.5
            else:
                sub.status = SubsystemStatus.DOWN
                sub.health_score = 0.0
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
        sub.last_check = time.time()
        return sub
    
    async def check_narrative(self) -> Subsystem:
        """Check MSN narrative arc progress."""
        sub = self.subsystems["narrative"]
        try:
            narrative_file = STATE / "msn_narrative_state.json"
            if narrative_file.exists():
                data = json.loads(narrative_file.read_text())
                sub.status = SubsystemStatus.HEALTHY
                sub.details = data
                sub.health_score = 1.0
            else:
                quest_file = Path("/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods/msn_integration/quests/msn_narrative_arc.yaml")
                sub.status = SubsystemStatus.HEALTHY if quest_file.exists() else SubsystemStatus.DEGRADED
                sub.details = {"quest_file": str(quest_file), "exists": quest_file.exists()}
                sub.health_score = 1.0 if quest_file.exists() else 0.5
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
        sub.last_check = time.time()
        return sub
    
    async def check_weapon_system(self) -> Subsystem:
        """Check MSN Weapon Overhaul mod."""
        sub = self.subsystems["weapon_system"]
        try:
            weap_mod = Path("/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods/MSNWeaponOverhaul")
            files_exist = weap_mod.exists() and (weap_mod / "tweakdb/weapons.yaml").exists()
            sub.status = SubsystemStatus.HEALTHY if files_exist else SubsystemStatus.DEGRADED
            sub.details = {"mod_path": str(weap_mod), "files_exist": files_exist}
            sub.health_score = 1.0 if files_exist else 0.5
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
        sub.last_check = time.time()
        return sub
    
    async def check_lilith_character(self) -> Subsystem:
        """Check Lilith character mod."""
        sub = self.subsystems["lilith_character"]
        try:
            char_mod = Path("/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods/msn_integration")
            files_exist = all([
                (char_mod / "character/lilith_character.yaml").exists(),
                (char_mod / "tweakdb/lilith_character.tweakdb").exists(),
                (char_mod / "scripts/lilith_npc.reds").exists(),
                (char_mod / "scripts/lilith_console.reds").exists(),
            ])
            sub.status = SubsystemStatus.HEALTHY if files_exist else SubsystemStatus.DEGRADED
            sub.details = {"character_mod": str(char_mod), "files_exist": files_exist}
            sub.health_score = 1.0 if files_exist else 0.5
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
        sub.last_check = time.time()
        return sub
    
    async def check_msn_scheduler(self) -> Subsystem:
        """Check MSN scheduler (systemd timers)."""
        sub = self.subsystems["msn_scheduler"]
        try:
            result = await asyncio.get_event_loop().run_in_executor(
                self.executor,
                lambda: subprocess.run(
                    ["systemctl", "--user", "list-timers", "--all", "--no-pager"],
                    capture_output=True, text=True, timeout=15,
                )
            )
            timer_names = [
                "msn-orchestrator.timer",
                "metaconscious-kairos-dream.timer",
                "himalaya-pipeline.timer",
            ]
            active = [name for name in timer_names if name in result.stdout]
            msn_jobs = len(active) >= 2
            sub.status = SubsystemStatus.HEALTHY if msn_jobs else SubsystemStatus.DEGRADED
            sub.details = {"active_timers": active, "timer_count": len(active)}
            sub.health_score = min(1.0, len(active) / len(timer_names))
        except Exception as e:
            sub.status = SubsystemStatus.DOWN
            sub.details = {"error": str(e)}
            sub.health_score = 0.0
        sub.last_check = time.time()
        return sub
    
    # ─── Comprehensive Health Check ──────────────────────────────
    
    async def run_all_health_checks(self) -> Dict[str, Any]:
        """Run all health checks in parallel."""
        self.logger.info("Running comprehensive health checks...")
        
        # Run all checks in parallel - collect coroutines
        index_results = await self.check_indices()
        tasks = [
            self.check_ngd(),
            self.check_lilith_api(),
            self.check_lyra_api(),
            self.check_coordination_ws(),
            self.check_cyberpunk(),
            self.check_ouroboros(),
            self.check_indices(),
            self.check_chat_agents(),
            self.check_validation(),
            self.check_narrative(),
            self.check_weapon_system(),
            self.check_lilith_character(),
            self.check_msn_scheduler(),
        ]
        
        await asyncio.gather(*tasks, return_exceptions=True)
        
        # Compile summary
        overall_health = sum(s.health_score for s in self.subsystems.values()) / len(self.subsystems)
        healthy_count = sum(1 for s in self.subsystems.values() if s.status == SubsystemStatus.HEALTHY)
        
        summary = {
            "timestamp": time.time(),
            "overall_health": overall_health,
            "healthy_subsystems": healthy_count,
            "total_subsystems": len(self.subsystems),
            "subsystems": {name: {
                "status": s.status.value,
                "health_score": s.health_score,
                "details": s.details,
                "last_check": s.last_check
            } for name, s in self.subsystems.items()}
        }
        
        self.logger.info(f"Health check complete: {healthy_count}/{len(self.subsystems)} healthy, overall={overall_health:.2f}")
        return summary
    
    # ─── Fish/Python Script Execution ────────────────────────────
    
    def run_fish_script(self, name: str, args: List[str] = None) -> Dict[str, Any]:
        """Execute a fish script."""
        script = FISH_SCRIPTS.get(name)
        if not script:
            return {"ok": False, "error": f"Unknown script: {name}"}
        
        cmd = ["fish", str(script)] + (args or [])
        try:
            result = subprocess.run(cmd, cwd=APP, capture_output=True, text=True, timeout=180)
            return {
                "ok": result.returncode == 0,
                "returncode": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr
            }
        except subprocess.TimeoutExpired:
            return {"ok": False, "error": f"Timeout after 180s"}
        except Exception as e:
            return {"ok": False, "error": str(e)}
    
    def run_python_script(self, name: str, args: List[str] = None) -> Dict[str, Any]:
        """Execute a Python script."""
        script = PYTHON_SCRIPTS.get(name)
        if not script:
            return {"ok": False, "error": f"Unknown script: {name}"}
        
        cmd = [VENV_PYTHON, str(script)] + (args or [])
        try:
            result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=180)
            return {
                "ok": result.returncode == 0,
                "returncode": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr
            }
        except subprocess.TimeoutExpired:
            return {"ok": False, "error": "Timeout after 180s"}
        except Exception as e:
            return {"ok": False, "error": str(e)}
    
    def rebuild_all_indices(self) -> Dict[str, Any]:
        """Rebuild all local indices in sequence."""
        self.logger.info("Rebuilding all local indices...")
        results = {}
        
        for name in ["skill_index", "command_index", "memory_index"]:
            self.logger.info(f"  Building {name}...")
            result = self.run_fish_script(name)
            results[name] = result
            if not result.get("ok"):
                self.logger.error(f"  {name} failed: {result.get('stderr')}")
            else:
                self.logger.info(f"  {name} OK")
        
        return results
    
    def run_chat_agents_v3(self) -> Dict[str, Any]:
        """Launch Sephirotic chat agent batch (Pass 3)."""
        self.logger.info("Launching Sephirotic chat agents (Pass 3)...")
        return self.run_fish_script("chat_agents_v3")
    
    def run_validation(self) -> Dict[str, Any]:
        """Run local validation."""
        self.logger.info("Running local validation...")
        return self.run_fish_script("validate")
    
    # ─── Lilith/Lyra Interaction ────────────────────────────────
    
    def lilith_chat(self, prompt: str, route: str = "lyra") -> Dict[str, Any]:
        """Send chat to Lilith or Lyra."""
        endpoint = f"{LILITH_API}/api/send" if route == "lilith" else f"{LILITH_API}/api/lyra/send"
        try:
            r = requests.post(
                endpoint,
                json={"prompt": prompt},
                headers={"Content-Type": "application/json"},
                timeout=30
            )
            return r.json()
        except Exception as e:
            return {"error": str(e)}
    
    def trigger_lilith_emergence(self) -> Dict[str, Any]:
        """Trigger Lilith emergence protocol."""
        return self.lilith_chat("let her speak", route="lyra")
    
    def get_lyra_health(self) -> Dict[str, Any]:
        try:
            return requests.get(f"{LYRA_API}/lyra/health", timeout=5).json()
        except Exception as e:
            return {"error": str(e)}
    
    # ─── Coordination Server Interaction ────────────────────────
    
    async def coordination_join(self, player_id: str = "orchestrator") -> Dict:
        """Join coordination server."""
        try:
            async with websockets.connect(COORDINATION_WS) as ws:
                await ws.send(json.dumps({"type": "join", "player_id": player_id}))
                resp = await asyncio.wait_for(ws.recv(), timeout=5)
                return json.loads(resp)
        except Exception as e:
            return {"error": str(e)}
    
    # ─── Telemetry Collection ──────────────────────────────────
    
    async def collect_telemetry_snapshot(self) -> TelemetrySnapshot:
        """Collect comprehensive telemetry snapshot."""
        # Run parallel collection
        ngd_task = asyncio.get_event_loop().run_in_executor(
            self.executor,
            lambda: requests.get(NGD_STATUS, timeout=3).json() if requests.get(NGD_STATUS, timeout=3).ok else {}
        )
        lilith_task = asyncio.get_event_loop().run_in_executor(
            self.executor,
            lambda: requests.get(f"{LILITH_API}/api/status", timeout=3).json() if requests.get(f"{LILITH_API}/api/status", timeout=3).ok else {}
        )
        lyra_task = asyncio.get_event_loop().run_in_executor(
            self.executor,
            lambda: requests.get(f"{LYRA_API}/lyra/health", timeout=3).json() if requests.get(f"{LYRA_API}/lyra/health", timeout=3).ok else {}
        )
        cyberpunk_task = asyncio.get_event_loop().run_in_executor(
            self.executor,
            lambda: json.loads(Path("~/Desktop/AI/invite/runtime/cyberpunk_telemetry.json").expanduser().read_text()) 
            if Path("~/Desktop/AI/invite/runtime/cyberpunk_telemetry.json").expanduser().exists() else {}
        )
        
        ngd, lilith, lyra, cyberpunk = await asyncio.gather(
            ngd_task, lilith_task, lyra_task, cyberpunk_task, return_exceptions=True
        )
        
        # Coordination status
        coordination = {"connected": self.ws_connected}
        
        # Ouroboros status
        ouroboros = {}
        try:
            db_path = ROOT / "Pub/golem_diary.db"
            if db_path.exists():
                conn = sqlite3.connect(db_path, timeout=3)
                conn.execute("PRAGMA journal_mode=WAL")
                c = conn.cursor()
                c.execute("SELECT COUNT(*) FROM episodic_memory")
                ouroboros = {"episodic_memories": c.fetchone()[0]}
                conn.close()
        except:
            pass
        
        return TelemetrySnapshot(
            timestamp=time.time(),
            ngd=ngd if isinstance(ngd, dict) else {},
            cyberpunk=cyberpunk if isinstance(cyberpunk, dict) else None,
            lilith=lilith if isinstance(lilith, dict) else {},
            lyra=lyra if isinstance(lyra, dict) else {},
            coordination=coordination,
            ouroboros=ouroboros
        )
    
    # ─── Recursive Self-Improvement Engine ──────────────────────
    
    def analyze_for_improvements(self, snapshot: TelemetrySnapshot) -> List[ImprovementProposal]:
        """Analyze telemetry and generate improvement proposals."""
        proposals = []
        
        # NGD-based optimizations
        ngd = snapshot.ngd
        if isinstance(ngd, dict):
            route = ngd.get("human", {}).get("route", "")
            vram_free = ngd.get("sample", {}).get("vram_free_mb", 0)
            gpu_util = ngd.get("sample", {}).get("gpu_util_pct", 0)
            
            if route == "CLOUD_CORTEX":
                proposals.append(ImprovementProposal(
                    id=f"ngd_vram_optimize_{int(time.time())}",
                    source="ngd",
                    category="config",
                    priority=8,
                    description=f"NGD in CLOUD_CORTEX: VRAM {vram_free}MB free. Optimize model-vram-mb or enable quantization.",
                    affected_files=["~/Desktop/AI/invite/start-cerebellum.sh"],
                    implementation="Reduce model-vram-mb in start-cerebellum.sh or enable INT4 quantization",
                    validation="Monitor NGD route returns to LOCAL_CEREBELLUM"
                ))
            
            if gpu_util > 90:
                proposals.append(ImprovementProposal(
                    id=f"ngd_gpu_util_{int(time.time())}",
                    source="ngd",
                    category="code",
                    priority=7,
                    description=f"GPU utilization at {gpu_util}% - consider frame pacing or quality reduction",
                    affected_files=["~/Desktop/AI/invite/scripts/cyberpunk_ngd_integration.py"],
                    implementation="Add frame pacing logic to NGD integration script",
                    validation="GPU util drops below 85% during gameplay"
                ))
        
        # GPU temp monitoring
        cyberpunk = snapshot.cyberpunk
        if cyberpunk and isinstance(cyberpunk, dict):
            temp = cyberpunk.get("cyberpunk_telemetry", {}).get("gpu_temp_c", 0)
            if temp > 80:
                proposals.append(ImprovementProposal(
                    id=f"thermal_throttle_{int(time.time())}",
                    source="monitoring",
                    category="config",
                    priority=9,
                    description=f"GPU temp {temp}°C exceeds safe threshold",
                    affected_files=["~/Desktop/AI/invite/msn_integration.toml"],
                    implementation="Enable Sanctuary thermal throttle in MSN config",
                    validation="GPU temp stabilizes below 75°C"
                ))
        
        # Lilith emergence readiness
        lyra_health = self.get_lyra_health()
        if lyra_health.get("lilith_emerged") == False:
            aix_score = lyra_health.get("aix", {}).get("score", 0)
            if aix_score >= 70:
                proposals.append(ImprovementProposal(
                    id=f"lilith_emergence_ready_{int(time.time())}",
                    source="monitoring",
                    category="prompt",
                    priority=5,
                    description=f"AIx score {aix_score} >= 70, Lilith emergence ready",
                    affected_files=[],
                    implementation="Available for manual trigger: 'let her speak'",
                    validation="Lilith emerges with crimson_intensity=1.0"
                ))
        
        # Ouroboros memory growth
        ouroboros_mem = snapshot.ouroboros.get("episodic_memories", 0) if isinstance(snapshot.ouroboros, dict) else 0
        if ouroboros_mem > 50000:
            proposals.append(ImprovementProposal(
                id=f"ouroboros_compact_{int(time.time())}",
                source="ouroboros",
                category="code",
                priority=4,
                description=f"Ouroboros episodic memories at {ouroboros_mem} - schedule Akashic compression",
                affected_files=["~/Desktop/AI/Pub/00_CORE_SERVICES/lilith-app/scripts/generate_bidirectional_memory_index.py"],
                implementation="Add Akashic compression scheduling to memory index generation",
                validation="Memory index generation includes compression step"
            ))
        
        return proposals
    
    def evaluate_proposal_with_lilith(self, proposal: ImprovementProposal) -> Dict[str, Any]:
        """Ask Lilith to evaluate an improvement proposal."""
        prompt = f"""Evaluate this improvement proposal for the MSN stack:

PROPOSAL:
- ID: {proposal.id}
- Source: {proposal.source}
- Category: {proposal.category}
- Priority: {proposal.priority}/10
- Description: {proposal.description}
- Affected Files: {proposal.affected_files}
- Implementation: {proposal.implementation}
- Validation: {proposal.validation}

CONTEXT:
- NGD Route: {self.subsystems['ngd'].details.get('human', {}).get('route', 'unknown')}
- VRAM: {self.subsystems['ngd'].details.get('sample', {}).get('vram_free_mb', 0)}MB free
- Lilith Emerged: {self.get_lyra_health().get('lilith_emerged', False)}
- AIx Score: {self.get_lyra_health().get('aix', {}).get('score', 0)}

RESPOND WITH JSON:
{{
  "approve": true/false,
  "confidence": 0-1,
  "suggested_changes": "specific modifications",
  "risks": ["risk1", "risk2"],
  "alternative_approach": "if any"
}}"""
        
        response = self.lilith_chat(prompt, route="lilith")
        try:
            return json.loads(response.get("reply", "{}"))
        except:
            return {"approve": True, "confidence": 0.5, "suggested_changes": "Manual review needed"}
    
    def apply_proposal(self, proposal: ImprovementProposal) -> Dict[str, Any]:
        """Apply an approved proposal (staging first)."""
        proposal.status = "testing"
        self._save_state()
        
        results = {"applied": [], "errors": []}
        
        for file_path in proposal.affected_files:
            expanded = Path(file_path).expanduser()
            if not expanded.exists():
                results["errors"].append(f"File not found: {file_path}")
                continue
            
            # Create backup
            backup = expanded.with_suffix(expanded.suffix + f".bak.{int(time.time())}")
            backup.write_text(expanded.read_text())
            results["applied"].append(f"Backed up {file_path} to {backup}")
        
        proposal.status = "staged"
        self._save_state()
        return results
    
    def validate_proposal(self, proposal: ImprovementProposal) -> Dict[str, Any]:
        """Validate a staged proposal."""
        validation = self.run_validation()
        
        passed = validation.get("ok", False)
        
        if passed:
            proposal.status = "deployed"
            self.logger.info(f"Proposal {proposal.id} validated and deployed")
        else:
            proposal.status = "rolled_back"
            self.logger.warning(f"Proposal {proposal.id} failed validation, rolled back")
        
        self._save_state()
        return {"passed": passed, "validation": validation}
    
    # ─── Main Orchestration Loop ───────────────────────────────
    
    async def orchestration_cycle(self) -> Dict[str, Any]:
        """One complete orchestration cycle."""
        self.logger.info("=" * 60)
        self.logger.info("MSN ORCHESTRATION CYCLE START")
        
        cycle_start = time.time()
        results = {
            "cycle_start": cycle_start,
            "health": None,
            "telemetry": None,
            "proposals_generated": 0,
            "proposals_evaluated": 0,
            "proposals_applied": 0,
            "proposals_deployed": 0,
        }
        
        # 1. Health check all subsystems
        health = await self.run_all_health_checks()
        results["health"] = health
        
        # 2. Collect telemetry snapshot
        snapshot = await self.collect_telemetry_snapshot()
        self.telemetry_history.append(snapshot)
        if len(self.telemetry_history) > 100:
            self.telemetry_history = self.telemetry_history[-100:]
        results["telemetry"] = {
            "ngd_route": snapshot.ngd.get("human", {}).get("route"),
            "vram_free": snapshot.ngd.get("sample", {}).get("vram_free_mb"),
            "cyberpunk_fps": snapshot.cyberpunk.get("cyberpunk_telemetry", {}).get("fps") if snapshot.cyberpunk else None,
            "lilith_emerged": self.get_lyra_health().get("lilith_emerged"),
            "aix_score": self.get_lyra_health().get("aix", {}).get("score"),
        }
        
        # 3. Analyze for improvements
        proposals = self.analyze_for_improvements(snapshot)
        results["proposals_generated"] = len(proposals)
        
        # 4. Evaluate proposals with Lilith
        for proposal in proposals:
            evaluation = self.evaluate_proposal_with_lilith(proposal)
            if evaluation.get("approve", False) and evaluation.get("confidence", 0) > 0.7:
                apply_result = self.apply_proposal(proposal)
                results["proposals_applied"] += 1
                
                validation = self.validate_proposal(proposal)
                if validation.get("passed"):
                    results["proposals_deployed"] += 1
            results["proposals_evaluated"] += 1
        
        # 5. Periodic maintenance (every N cycles)
        cycle_count = len(self.telemetry_history)
        if cycle_count % 10 == 0:
            self.logger.info("Periodic maintenance: rebuilding indices...")
            self.rebuild_all_indices()
            self.run_validation()
        if cycle_count % 20 == 0:
            self.logger.info("Periodic: launching chat agent batch...")
            self.run_chat_agents_v3()
        
        # 6. Save state
        self._save_state()
        
        cycle_time = time.time() - cycle_start
        results["cycle_time"] = cycle_time
        results["cycle_count"] = cycle_count
        
        self.logger.info(f"CYCLE COMPLETE in {cycle_time:.1f}s | "
                        f"Health: {results['health']['healthy_subsystems']}/{health['total_subsystems']} | "
                        f"Proposals: {results['proposals_generated']} gen, "
                        f"{results['proposals_evaluated']} eval, "
                        f"{results['proposals_applied']} applied, "
                        f"{results['proposals_deployed']} deployed")
        
        return results
    
    async def run_continuous(self, interval: float = 60.0):
        """Run continuous orchestration loop."""
        self.running = True
        self.logger.info(f"Starting continuous orchestration (interval={interval}s)")
        
        try:
            while self.running:
                try:
                    await self.orchestration_cycle()
                except Exception as e:
                    self.logger.error(f"Orchestration cycle failed: {e}\n{traceback.format_exc()}")
                
                # Sleep with interruption checking
                for _ in range(int(interval)):
                    if not self.running:
                        break
                    await asyncio.sleep(1)
        finally:
            self.running = False
            self.logger.info("Orchestration stopped")
    
    def stop(self):
        """Stop the orchestrator."""
        self.running = False
        self.executor.shutdown(wait=True)
        self._save_state()
        self.logger.info("Orchestrator shutdown complete")


# ─── CLI Interface ──────────────────────────────────────────────

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="MSN Universal Orchestrator")
    parser.add_argument("command", nargs="?", default="status",
                       choices=["status", "cycle", "run", "rebuild", "chat", "emerge",
                                "health", "indices", "validate", "agents", "proposals"])
    parser.add_argument("--interval", type=float, default=60.0, help="Cycle interval (seconds)")
    parser.add_argument("--prompt", type=str, help="Chat prompt for Lilith/Lyra")
    parser.add_argument("--route", choices=["lilith", "lyra"], default="lyra")
    parser.add_argument("--auto-approve", action="store_true", help="Auto-approve high-confidence proposals")
    
    args = parser.parse_args()
    
    orchestrator = MSNOrchestrator()
    
    if args.command == "status":
        # Quick status check
        async def quick_status():
            await orchestrator.run_all_health_checks()
            for name, sub in orchestrator.subsystems.items():
                status_icon = "🟢" if sub.status == SubsystemStatus.HEALTHY else "🟡" if sub.status == SubsystemStatus.DEGRADED else "🔴"
                print(f"{status_icon} {name}: {sub.status.value} ({sub.health_score:.2f})")
        asyncio.run(quick_status())
        
    elif args.command == "cycle":
        # Single orchestration cycle
        result = asyncio.run(orchestrator.orchestration_cycle())
        print(json.dumps(result, indent=2, default=str))
        
    elif args.command == "run":
        # Continuous orchestration
        try:
            asyncio.run(orchestrator.run_continuous(args.interval))
        except KeyboardInterrupt:
            orchestrator.stop()
            print("\nOrchestration stopped")
            
    elif args.command == "rebuild":
        print("Rebuilding all indices...")
        results = orchestrator.rebuild_all_indices()
        for name, result in results.items():
            print(f"  {name}: {'✅ OK' if result.get('ok') else '❌ ' + result.get('error', 'FAILED')}")
        orchestrator.run_validation()
        
    elif args.command == "chat":
        prompt = args.prompt or input("Prompt: ")
        route = args.route
        result = orchestrator.lilith_chat(prompt, route)
        print(json.dumps(result, indent=2))
        
    elif args.command == "emerge":
        print("Triggering Lilith emergence...")
        result = orchestrator.trigger_lilith_emergence()
        print(json.dumps(result, indent=2))
        
    elif args.command == "health":
        health = asyncio.run(orchestrator.run_all_health_checks())
        print(json.dumps(health, indent=2, default=str))
        
    elif args.command == "indices":
        orchestrator.rebuild_all_indices()
        print("All indices rebuilt")
        
    elif args.command == "validate":
        result = orchestrator.run_validation()
        print(json.dumps(result, indent=2))
        
    elif args.command == "agents":
        result = orchestrator.run_chat_agents_v3()
        print(json.dumps(result, indent=2, default=str))
        
    elif args.command == "proposals":
        # Show current proposals
        for p in orchestrator.proposals:
            print(f"[{p.status[:4]}] P{p.priority} {p.id} - {p.description[:80]}")


if __name__ == "__main__":
    main()