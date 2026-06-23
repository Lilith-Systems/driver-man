#!/usr/bin/env python3
"""Cerebellum/tool bridge for Lilith server local memory."""
from __future__ import annotations
import logging
import os
import sys
from typing import Optional

log = logging.getLogger("lilith.memory_bridge")
CEREBELLUM_CLIENT_PATH = os.getenv(
    "CEREBELLUM_CLIENT_PATH",
    "/home/tehlappy/.hermes/skills/metaconscious/concurrent-bidirectional-memory/scripts",
)
if CEREBELLUM_CLIENT_PATH not in sys.path:
    sys.path.insert(0, CEREBELLUM_CLIENT_PATH)

try:
    from cerebellum_client import CerebellumClient, CerebellumConfig
except Exception as exc:  # pragma: no cover
    raise ImportError(f"cerebellum_client import failed: {exc}") from exc

_DEFAULT_DB = "/home/tehlappy/Desktop/AI/Pub/00_CORE_SERVICES/quantum_paradox_terminal/golem_diary.db"
_DEFAULT_LYRA = "http://localhost:3211"


def build_client(db_path: Optional[str] = None, lyra_base: Optional[str] = None) -> CerebellumClient:
    return CerebellumClient(CerebellumConfig(
        db_path=db_path or os.getenv("GOLEM_DB_PATH", _DEFAULT_DB),
        lyra_base=lyra_base or os.getenv("LYRA_BASE", _DEFAULT_LYRA),
        use_http=True,
    ))
