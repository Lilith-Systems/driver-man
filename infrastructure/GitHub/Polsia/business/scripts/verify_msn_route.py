#!/usr/bin/env python3
"""Smoke-test Lilith's MSN routing and chat path."""

from __future__ import annotations

import json
import os
import sys
from typing import Any

import httpx


PORT = int(os.getenv("LILITH_PORT", "3213"))
BASE_URL = os.getenv("LILITH_BASE_URL", f"http://127.0.0.1:{PORT}")
PROMPT = os.getenv(
    "LILITH_ROUTE_PROMPT",
    "our LLM Lilith sucks i need you to work on The MSN skills symbiosis and integration",
)


def fail(message: str, code: int = 1) -> "NoReturn":
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(code)


def get_json(client: httpx.Client, path: str) -> Any:
    response = client.get(f"{BASE_URL}{path}")
    response.raise_for_status()
    return response.json()


def post_json(client: httpx.Client, path: str, payload: dict[str, Any]) -> Any:
    response = client.post(f"{BASE_URL}{path}", json=payload)
    response.raise_for_status()
    return response.json()


def main() -> None:
    with httpx.Client(timeout=60.0) as client:
        health = get_json(client, "/health")
        if not health.get("ok"):
            fail(f"health check failed: {json.dumps(health, sort_keys=True)}")

        route = post_json(client, "/api/msn/route", {"prompt": PROMPT})
        focus_categories = route.get("focus_categories", [])
        selected_skills = route.get("selected_skills", [])
        selected_commands = route.get("selected_commands", [])
        if not selected_skills:
            fail("route returned no selected skills")
        if not selected_commands:
            fail("route returned no selected commands")
        if not any(cat in {"ops", "memory"} for cat in focus_categories):
            fail(f"route focus categories were not relevant: {focus_categories}")

        chat = post_json(client, "/v1/chat", {"messages": [{"role": "user", "content": PROMPT}]})
        reply = str(chat.get("reply", "")).strip()
        if not reply:
            fail("chat returned an empty reply")

        summary = {
            "health": {
                "skill_index": health.get("skill_index"),
                "command_index": health.get("command_index"),
                "bridge_index": health.get("bridge_index"),
                "validation_ok": health.get("validation_ok"),
            },
            "route": {
                "focus_categories": focus_categories,
                "focus_roles": route.get("focus_roles", []),
                "selected_skills": [item.get("name") for item in selected_skills],
                "selected_commands": [item.get("name") for item in selected_commands],
            },
            "reply_preview": reply[:240],
        }
        print(json.dumps(summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
