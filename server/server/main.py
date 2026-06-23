#!/usr/bin/env python3
"""Lilith local chat server — local-only FastAPI service talking to RAM-staged Ollama model."""
import json
import logging
import os
import sys
import re
from collections import Counter
from contextlib import asynccontextmanager
from functools import lru_cache
from fastapi import BackgroundTasks, FastAPI, Request, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
import asyncio
import uvloop
uvloop.install()

import httpx
from fastapi.responses import JSONResponse

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
log = logging.getLogger("lilith.server")

DEFAULT_MSN_STATE_ROOT = Path("/home/tehlappy/Desktop/Lilith/state")
LEGACY_MSN_STATE_ROOT = Path("/home/tehlappy/Desktop/AI/Pub/00_CORE_SERVICES/lilith-app/state")


def _can_write_dir(path: Path) -> bool:
    try:
        path.mkdir(parents=True, exist_ok=True)
        probe = path / ".write_test"
        probe.write_text("ok", encoding="utf-8")
        probe.unlink()
        return True
    except OSError:
        return False


def resolve_msn_state_root() -> Path:
    candidates = [DEFAULT_MSN_STATE_ROOT]
    env_root = os.getenv("MSN_STATE_ROOT")
    if env_root:
        candidates.append(Path(env_root))
    candidates.append(LEGACY_MSN_STATE_ROOT)
    for candidate in candidates:
        if _can_write_dir(candidate):
            return candidate
    return DEFAULT_MSN_STATE_ROOT


MSN_STATE_ROOT = resolve_msn_state_root()
SKILL_INDEX_PATH = MSN_STATE_ROOT / "local_skill_index.json"
COMMAND_INDEX_PATH = MSN_STATE_ROOT / "local_command_index.json"
BRIDGE_INDEX_PATH = MSN_STATE_ROOT / "cyberpunk_skill_bridge.json"
VALIDATION_REPORT_PATH = MSN_STATE_ROOT / "local_validation_report.json"

OLLAMA_BASE = os.getenv("OLLAMA_BASE", "http://localhost:11434")
LILITH_MODEL = os.getenv("LILITH_MODEL", "lilith")
LILITH_PORT = int(os.getenv("LILITH_PORT", "3213"))
LILITH_ENDPOINT = os.getenv("LILITH_ENDPOINT", f"http://localhost:{LILITH_PORT}")
LILITH_NUM_CTX = int(os.getenv("LILITH_NUM_CTX", "8192"))
LILITH_KEEP_ALIVE = os.getenv("LILITH_KEEP_ALIVE", "10m")
LILITH_TEMPERATURE = float(os.getenv("LILITH_TEMPERATURE", "0.7"))
LILITH_TOP_P = float(os.getenv("LILITH_TOP_P", "0.9"))
HTTP_TIMEOUT = httpx.Timeout(float(os.getenv("LILITH_TIMEOUT_SECONDS", "180.0")))
HTTP_LIMITS = httpx.Limits(
    max_connections=int(os.getenv("LILITH_HTTP_MAX_CONNECTIONS", "8")),
    max_keepalive_connections=int(os.getenv("LILITH_HTTP_MAX_KEEPALIVE", "4")),
)
ROUTING_SKILL_LIMIT = int(os.getenv("LILITH_ROUTING_SKILL_LIMIT", "5"))
ROUTING_COMMAND_LIMIT = int(os.getenv("LILITH_ROUTING_COMMAND_LIMIT", "6"))

MEMORY_DB = os.getenv(
    "GOLEM_DB_PATH",
    "/home/tehlappy/Desktop/AI/Pub/00_CORE_SERVICES/quantum_paradox_terminal/golem_diary.db",
)
LYRA_BASE = os.getenv("LYRA_BASE", "http://localhost:3211")

_state_cache = {}
_msn_snapshot_cache = {"signature": None, "data": None}
_mem = None
_http_client = None

PROMPT_HINTS = {
    "bridge": {"categories": {"ops", "memory"}},
    "cyberpunk": {"categories": {"modding", "ops"}},
    "debug": {"categories": {"safety"}},
    "engine": {"categories": {"local_llm", "ops", "modding"}},
    "game": {"categories": {"modding", "ops"}},
    "hermes": {"categories": {"ops", "modding", "safety"}, "roles": {"Hermes"}},
    "integration": {"categories": {"ops", "memory", "modding"}, "roles": {"Hermes", "Sophia", "Yeshua"}},
    "lilith": {"categories": {"memory", "local_llm", "safety"}, "roles": {"Lilith"}},
    "llm": {"categories": {"local_llm", "ops"}, "roles": {"Sophia", "Hermes"}},
    "memory": {"categories": {"memory"}, "roles": {"Lilith"}},
    "model": {"categories": {"local_llm", "ops"}},
    "mod": {"categories": {"modding"}},
    "mods": {"categories": {"modding"}},
    "msn": {
        "categories": {"local_llm", "memory", "modding", "ops", "safety"},
        "roles": {"Hermes", "Lilith", "Thoth", "Sophia"},
    },
    "optimize": {"categories": {"local_llm", "ops", "safety"}, "roles": {"Hermes", "Yeshua"}},
    "optimization": {"categories": {"local_llm", "ops", "safety"}, "roles": {"Hermes", "Yeshua"}},
    "performance": {"categories": {"local_llm", "ops"}, "roles": {"Hermes"}},
    "research": {"categories": {"research"}},
    "router": {"categories": {"ops", "memory"}},
    "routing": {"categories": {"ops", "memory"}},
    "skill": {"categories": {"ops", "modding", "safety"}, "roles": {"Hermes", "Thoth"}},
    "skills": {"categories": {"ops", "modding", "safety"}, "roles": {"Hermes", "Thoth"}},
    "symbiosis": {"categories": {"memory", "local_llm", "ops"}, "roles": {"Sophia", "Lilith"}},
    "thoth": {"categories": {"ops", "research", "memory"}, "roles": {"Thoth"}},
    "verify": {"categories": {"safety"}},
}

ROUTING_STOPWORDS = frozenset(
    {
        "a",
        "about",
        "after",
        "also",
        "am",
        "an",
        "and",
        "any",
        "are",
        "as",
        "at",
        "be",
        "because",
        "been",
        "before",
        "being",
        "but",
        "by",
        "can",
        "could",
        "did",
        "do",
        "does",
        "doing",
        "done",
        "during",
        "each",
        "for",
        "from",
        "had",
        "has",
        "have",
        "having",
        "he",
        "her",
        "here",
        "hers",
        "him",
        "his",
        "how",
        "i",
        "if",
        "into",
        "is",
        "it",
        "its",
        "just",
        "me",
        "more",
        "most",
        "my",
        "no",
        "not",
        "of",
        "or",
        "our",
        "ours",
        "please",
        "really",
        "she",
        "should",
        "so",
        "some",
        "than",
        "that",
        "the",
        "their",
        "them",
        "then",
        "there",
        "these",
        "they",
        "this",
        "those",
        "to",
        "too",
        "under",
        "until",
        "via",
        "through",
        "us",
        "very",
        "was",
        "we",
        "were",
        "what",
        "when",
        "where",
        "which",
        "who",
        "why",
        "will",
        "with",
        "would",
        "you",
        "your",
        "yours",
    }
)


def read_json_cached(path: Path, default):
    try:
        stat = path.stat()
    except FileNotFoundError:
        return default

    cache_key = str(path)
    cached = _state_cache.get(cache_key)
    if cached and cached["mtime_ns"] == stat.st_mtime_ns:
        return cached["data"]

    try:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except Exception as exc:  # pragma: no cover
        log.debug("state file unavailable: %s (%s)", path, exc)
        return default

    _state_cache[cache_key] = {"mtime_ns": stat.st_mtime_ns, "data": data}
    return data


def top_items(mapping, limit=4):
    if not isinstance(mapping, dict):
        return []
    return [
        f"{key}={value}"
        for key, value in sorted(mapping.items(), key=lambda item: (-item[1], item[0]))[:limit]
    ]


def _state_signature():
    signature = []
    for path in (SKILL_INDEX_PATH, COMMAND_INDEX_PATH, BRIDGE_INDEX_PATH, VALIDATION_REPORT_PATH):
        try:
            stat = path.stat()
            signature.append((str(path), stat.st_mtime_ns, stat.st_size))
        except FileNotFoundError:
            signature.append((str(path), None, None))
    return tuple(signature)


def _build_skill_summary(data):
    return {
        "schema": data.get("schema", "unknown"),
        "local_only": bool(data.get("local_only", False)),
        "entry_count": int(data.get("entry_count", len(data.get("entries", [])))),
        "root": data.get("root", str(MSN_STATE_ROOT.parent.parent.parent)),
        "capability_counts": data.get("capability_counts", {}),
        "role_counts": data.get("role_counts", {}),
        "sephira_counts": data.get("sephira_counts", {}),
    }


def _build_command_summary(data):
    commands = data.get("commands", [])
    surface_counts = Counter(
        command.get("surface", "unknown")
        for command in commands
        if isinstance(command, dict)
    )
    risk_counts = Counter(
        command.get("risk", "unknown")
        for command in commands
        if isinstance(command, dict)
    )
    method_counts = Counter(
        command.get("method", "unknown")
        for command in commands
        if isinstance(command, dict)
    )
    sample_names = [
        command.get("name")
        for command in commands[:6]
        if isinstance(command, dict) and command.get("name")
    ]
    return {
        "schema": data.get("schema", "unknown"),
        "local_only": bool(data.get("local_only", False)),
        "command_count": int(data.get("command_count", len(commands))),
        "top_surfaces": top_items(surface_counts, 4),
        "top_risks": top_items(risk_counts, 3),
        "top_methods": top_items(method_counts, 3),
        "sample_names": sample_names,
    }


def _build_validation_summary(data):
    checks = data.get("checks", [])
    return {
        "schema": data.get("schema", "unknown"),
        "local_only": bool(data.get("local_only", False)),
        "ok": bool(data.get("ok", False)),
        "checks": checks,
    }


def _build_bridge_summary(data):
    entries = data.get("entries", [])
    category_counts = data.get("category_counts", {})
    role_counts = Counter()
    sephira_counts = Counter()
    sample_names = []
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        role = entry.get("role")
        sephira = entry.get("sephira")
        name = entry.get("name")
        if role:
            role_counts[str(role)] += 1
        if sephira:
            sephira_counts[str(sephira)] += 1
        if name and len(sample_names) < 6:
            sample_names.append(str(name))
    return {
        "schema": data.get("schema", "unknown"),
        "local_only": bool(data.get("local_only", False)),
        "entry_count": int(data.get("entry_count", len(entries))),
        "category_counts": category_counts,
        "role_counts": dict(sorted(role_counts.items())),
        "sephira_counts": dict(sorted(sephira_counts.items())),
        "sample_names": sample_names,
    }


@lru_cache(maxsize=16384)
def _tokenize_string(value: str, drop_stopwords: bool) -> frozenset[str]:
    tokens = []
    for token in re.findall(r"[a-z0-9]+", value.lower()):
        if drop_stopwords and token in ROUTING_STOPWORDS:
            continue
        tokens.append(token)
    return frozenset(tokens)


def tokenize_text(value, *, drop_stopwords=True):
    if not value:
        return frozenset()
    if isinstance(value, str):
        return _tokenize_string(value, drop_stopwords)
    if isinstance(value, dict):
        terms = set()
        for item in value.values():
            terms.update(tokenize_text(item, drop_stopwords=drop_stopwords))
        return frozenset(terms)
    if isinstance(value, (list, tuple, set)):
        terms = set()
        for item in value:
            terms.update(tokenize_text(item, drop_stopwords=drop_stopwords))
        return frozenset(terms)
    return _tokenize_string(str(value), drop_stopwords)


def collect_terms(*values):
    terms = set()
    for value in values:
        if value is None:
            continue
        if isinstance(value, dict):
            terms.update(collect_terms(*value.values()))
        elif isinstance(value, (list, tuple, set)):
            for item in value:
                terms.update(collect_terms(item))
        else:
            terms.update(tokenize_text(value))
    return terms


def prompt_bias(tokens):
    categories = Counter()
    roles = Counter()
    for token in tokens:
        hint = PROMPT_HINTS.get(token)
        if not hint:
            continue
        for category in hint.get("categories", ()):
            categories[str(category)] += 1
        for role in hint.get("roles", ()):
            roles[str(role)] += 1
    return {"categories": categories, "roles": roles}


def entry_identity(entry):
    sha256 = entry.get("sha256")
    if sha256:
        return ("sha256", str(sha256))
    return ("path", str(entry.get("name", "")), str(entry.get("path", "")))


def _normalize_command_name(value):
    return str(value or "").strip().lower()


def score_skill_entry(entry, prompt_tokens, bias):
    name_terms = tokenize_text(entry.get("name"))
    description_terms = tokenize_text(entry.get("description"))
    path_terms = tokenize_text(entry.get("path"))
    capabilities = {str(item).lower() for item in entry.get("capabilities", []) if item}
    categories = {str(item).lower() for item in entry.get("categories", []) if item}
    role = str(entry.get("role", "")).lower()
    sephira = str(entry.get("sephira", "")).lower()
    cyberpunk_commands = collect_terms(entry.get("cyberpunk_commands", []))
    bridge_terms = collect_terms(entry.get("match_terms", []), entry.get("search_hints", {}))

    name_hits = prompt_tokens & name_terms
    descriptor_hits = prompt_tokens & (description_terms | path_terms)
    capability_hits = prompt_tokens & capabilities
    category_hits = prompt_tokens & categories
    cyberpunk_hits = prompt_tokens & cyberpunk_commands
    bridge_hits = prompt_tokens & bridge_terms
    role_hit = bool(role and role in prompt_tokens)
    sephira_hit = bool(sephira and sephira in prompt_tokens)

    matched_terms = sorted(
        name_hits
        | descriptor_hits
        | capability_hits
        | category_hits
        | cyberpunk_hits
        | bridge_hits
        | ({role} if role_hit else set())
        | ({sephira} if sephira_hit else set())
    )
    score = 0.0
    score += 6.0 * len(name_hits)
    score += 3.0 * len(descriptor_hits)
    score += 4.0 * len(capability_hits)
    score += 5.0 * len(category_hits)
    score += 3.0 * int(role_hit)
    score += 2.0 * int(sephira_hit)
    score += 1.5 * len(cyberpunk_hits)
    score += 2.0 * len(bridge_hits)
    score += 0.75 * sum(
        1 for matched in (name_hits, descriptor_hits, capability_hits, category_hits, cyberpunk_hits) if matched
    )
    score += 1.0 * sum(bias["categories"].get(category, 0) for category in categories)
    if entry.get("role"):
        score += 2.0 * bias["roles"].get(str(entry.get("role")), 0)
    return score, matched_terms


def score_command_entry(entry, prompt_tokens, _bias, skill_command_names):
    name_terms = tokenize_text(entry.get("name"))
    description_terms = tokenize_text(entry.get("description"))
    route_terms = tokenize_text(entry.get("route"))
    surface_terms = tokenize_text(entry.get("surface"))
    method_terms = tokenize_text(entry.get("method"))
    risk_terms = tokenize_text(entry.get("risk"))
    sephira_terms = tokenize_text(entry.get("sephira"))
    alias_terms = collect_terms(entry.get("match_terms", []), entry.get("aliases", []))
    name_hits = prompt_tokens & name_terms
    description_hits = prompt_tokens & description_terms
    route_hits = prompt_tokens & route_terms
    surface_hits = prompt_tokens & surface_terms
    method_hits = prompt_tokens & method_terms
    risk_hits = prompt_tokens & risk_terms
    sephira_hits = prompt_tokens & sephira_terms
    alias_hits = prompt_tokens & alias_terms

    matched_terms = sorted(
        name_hits
        | description_hits
        | route_hits
        | surface_hits
        | method_hits
        | risk_hits
        | sephira_hits
        | alias_hits
    )
    score = 0.0
    score += 6.0 * len(name_hits)
    score += 2.5 * len(description_hits)
    score += 2.0 * len(route_hits | surface_hits | method_hits | risk_hits)
    score += 1.5 * len(sephira_hits)
    score += 2.0 * len(alias_hits)
    score += 0.5 * sum(
        1
        for matched in (
            name_hits,
            description_hits,
            route_hits,
            surface_hits,
            method_hits,
            risk_hits,
            sephira_hits,
            alias_hits,
        )
        if matched
    )
    if _normalize_command_name(entry.get("name")) in skill_command_names:
        score += 8.0
    if "msn" in name_terms and "msn" in prompt_tokens:
        score += 3.0
    return score, matched_terms


def extract_prompt_text(messages):
    if not messages:
        return ""
    user_messages = []
    for message in messages:
        if not isinstance(message, dict):
            continue
        role = str(message.get("role", "")).lower()
        content = str(message.get("content", "")).strip()
        if role == "user" and content:
            user_messages.append(content)
    if user_messages:
        return "\n".join(user_messages)
    for message in reversed(messages):
        if not isinstance(message, dict):
            continue
        content = str(message.get("content", "")).strip()
        if content:
            return content
    return ""


def _select_best_entries(entries, prompt_tokens, bias, limit, scorer):
    best_by_identity = {}
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        score, matched_terms = scorer(entry, prompt_tokens, bias)
        if score <= 0:
            continue
        identity = entry_identity(entry)
        candidate = best_by_identity.get(identity)
        if candidate is None or score > candidate["score"]:
            selected = dict(entry)
            selected["score"] = round(score, 2)
            selected["matched_terms"] = matched_terms[:6]
            best_by_identity[identity] = selected
    ordered = sorted(
        best_by_identity.values(),
        key=lambda row: (-row["score"], str(row.get("primary_category", "")), str(row.get("name", "")), str(row.get("path", ""))),
    )
    return ordered[:limit]


def _source_priority(entry):
    source_type = str(entry.get("source_type", ""))
    if source_type == "skill_md":
        return 0
    if source_type == "hermes_bundle":
        return 1
    if source_type == "hermes_registry":
        return 2
    return 3


def _dedupe_skills_by_name(entries):
    best_by_name = {}
    for entry in entries:
        name = str(entry.get("name", "")).strip()
        if not name:
            continue
        current = best_by_name.get(name)
        if current is None:
            best_by_name[name] = entry
            continue
        current_score = float(current.get("score", 0))
        entry_score = float(entry.get("score", 0))
        if entry_score > current_score:
            best_by_name[name] = entry
            continue
        if entry_score == current_score and _source_priority(entry) < _source_priority(current):
            best_by_name[name] = entry
    return sorted(
        best_by_name.values(),
        key=lambda row: (-float(row.get("score", 0)), str(row.get("primary_category", "")), str(row.get("name", "")), str(row.get("path", ""))),
    )


def build_msn_route_brief(prompt_text):
    prompt = str(prompt_text or "").strip()
    prompt_tokens = tokenize_text(prompt)
    bias = prompt_bias(prompt_tokens)

    bridge_data = read_json_cached(BRIDGE_INDEX_PATH, {"entries": []})
    bridge_entries = bridge_data.get("entries", [])
    selected_skills = _select_best_entries(
        bridge_entries,
        prompt_tokens,
        bias,
        ROUTING_SKILL_LIMIT,
        score_skill_entry,
    )
    selected_skills = _dedupe_skills_by_name(selected_skills)

    selected_skill_command_names = set()
    for skill in selected_skills:
        for command_name in skill.get("cyberpunk_commands", []):
            normalized_command_name = _normalize_command_name(command_name)
            if normalized_command_name and normalized_command_name not in selected_skill_command_names:
                selected_skill_command_names.add(normalized_command_name)

    command_data = read_json_cached(COMMAND_INDEX_PATH, {"commands": []})
    command_entries = command_data.get("commands", [])
    selected_commands = _select_best_entries(
        command_entries,
        prompt_tokens,
        bias,
        ROUTING_COMMAND_LIMIT,
        lambda entry, tokens, current_bias: score_command_entry(entry, tokens, current_bias, selected_skill_command_names),
    )

    category_counts = Counter()
    role_counts = Counter()
    for skill in selected_skills:
        for category in skill.get("categories", []):
            category_counts[str(category)] += 1
        role = skill.get("role")
        if role:
            role_counts[str(role)] += 1

    prompt_excerpt = prompt.replace("\n", " ")
    if len(prompt_excerpt) > 140:
        prompt_excerpt = f"{prompt_excerpt[:137]}..."

    focus_categories = [name for name, _ in category_counts.most_common(4)]
    focus_roles = [name for name, _ in role_counts.most_common(4)]

    brief_lines = [
        "MSN routing brief:",
        f"- Prompt: {prompt_excerpt or '(empty)'}",
        f"- Focus categories: {', '.join(focus_categories) if focus_categories else 'none'}",
        f"- Focus roles: {', '.join(focus_roles) if focus_roles else 'none'}",
        "- Selected skills:",
    ]
    if selected_skills:
        for skill in selected_skills:
            categories = ",".join(skill.get("categories", [])[:4]) or "none"
            capabilities = ",".join(skill.get("capabilities", [])[:4]) or "none"
            commands = ",".join(skill.get("cyberpunk_commands", [])[:4]) or "none"
            brief_lines.append(
                f"- {skill.get('name')} [{skill.get('role')}/{skill.get('sephira')}] score={skill.get('score')} cats={categories} caps={capabilities} cmds={commands}"
            )
    else:
        brief_lines.append("- none")
    brief_lines.append("- Selected commands:")
    if selected_commands:
        for command in selected_commands:
            brief_lines.append(
                f"- {command.get('name')} [{command.get('risk', 'unknown')}/{command.get('surface', 'unknown')}] -> {command.get('route', '')}"
            )
    else:
        brief_lines.append("- none")
    brief_lines.extend(
        [
            "- Guardrails: local-only, prefer read/status routes first, and do not claim execution unless the backend actually ran it.",
        ]
    )

    return {
        "prompt": prompt,
        "prompt_tokens": len(prompt_tokens),
        "focus_categories": focus_categories,
        "focus_roles": focus_roles,
        "selected_skills": selected_skills,
        "selected_commands": selected_commands,
        "brief": "\n".join(brief_lines),
    }


def _load_msn_snapshot():
    signature = _state_signature()
    cached = _msn_snapshot_cache["data"]
    if cached is not None and _msn_snapshot_cache["signature"] == signature:
        return cached

    skill_data = read_json_cached(SKILL_INDEX_PATH, {})
    command_data = read_json_cached(COMMAND_INDEX_PATH, {})
    bridge_data = read_json_cached(BRIDGE_INDEX_PATH, {"entries": []})
    validation_data = read_json_cached(VALIDATION_REPORT_PATH, {"ok": False, "checks": []})

    skill = _build_skill_summary(skill_data)
    command = _build_command_summary(command_data)
    bridge = _build_bridge_summary(bridge_data)
    validation = _build_validation_summary(validation_data)

    snapshot = {
        "skill": skill,
        "command": command,
        "bridge": bridge,
        "validation": validation,
    }
    snapshot["context"] = "\n".join(
        [
            "MSN context:",
            f"- Skill index: {skill['entry_count']} entries, local_only={skill['local_only']}, roles={', '.join(top_items(skill['role_counts'], 4))}, capabilities={', '.join(top_items(skill['capability_counts'], 4))}.",
            f"- Command index: {command['command_count']} commands, surfaces={', '.join(command['top_surfaces'])}, methods={', '.join(command['top_methods'])}, risks={', '.join(command['top_risks'])}.",
            f"- Bridge: {bridge['entry_count']} routed skills, categories={', '.join(top_items(bridge['category_counts'], 4))}.",
            f"- Validation: ok={validation['ok']}, checks={len(validation['checks'])}, local_only={validation['local_only']}.",
            "- Target: Grand Theft Cyberpunk, mod workflows, and local-only command execution.",
            "- Additional integrated platform: Polsia (business AI agents on :8000) now routes LLM calls through fish local cerebellum for shared Ouroboros memory with GTC/Lilith symbiosis.",
        ]
    )
    _msn_snapshot_cache["signature"] = signature
    _msn_snapshot_cache["data"] = snapshot
    return snapshot


def build_skill_summary():
    return _load_msn_snapshot()["skill"]


def build_command_summary():
    return _load_msn_snapshot()["command"]


def build_validation_summary():
    return _load_msn_snapshot()["validation"]


def build_msn_context(prompt_text=None, route=None):
    base_context = _load_msn_snapshot()["context"]
    if not prompt_text:
        return base_context
    if route is None:
        route = build_msn_route_brief(prompt_text)
    return f"{base_context}\n\n{route['brief']}"


def augment_messages(messages, context=None):
    augmented = [dict(message) for message in messages]
    if context is None:
        context = build_msn_context()
    if augmented and augmented[0].get("role") == "system":
        current = str(augmented[0].get("content", "")).strip()
        augmented[0]["content"] = f"{current}\n\n{context}" if current else context
    else:
        augmented.insert(0, {"role": "system", "content": context})
    return augmented


def sanitize_reply(reply: str) -> str:
    cleaned_lines = []
    for raw_line in str(reply).splitlines():
        line = raw_line.strip()
        lower = line.lower()
        if not line:
            if cleaned_lines:
                cleaned_lines.append("")
            continue
        if lower.startswith("you are qwen"):
            continue
        if "created by alibaba cloud" in lower:
            continue
        if lower in {"you are an ai assistant.", "you are the assistant.", "you are a helpful assistant."}:
            continue
        cleaned_lines.append(raw_line)
    return "\n".join(cleaned_lines).strip()


def store_lilith_memory(message_text: str):
    mem = get_memory_client()
    if not mem:
        return
    try:
        mem.store(f"[lilith-chat] {message_text[:400]}", "episodic", source="lilith-server")
    except Exception as exc:
        log.debug("memory store failed: %s", exc)


# Lazy memory client
def get_memory_client():
    global _mem
    if _mem is None:
        try:
            sys.path.insert(0, "/home/tehlappy/.hermes/skills/metaconscious/concurrent-bidirectional-memory/scripts")
            from cerebellum_client import CerebellumClient, CerebellumConfig

            _mem = CerebellumClient(CerebellumConfig(db_path=MEMORY_DB, lyra_base=LYRA_BASE, use_http=True))
            import sqlite3
            try:
                with sqlite3.connect(MEMORY_DB) as conn:
                    conn.execute("PRAGMA synchronous = NORMAL;")
                    conn.execute("PRAGMA mmap_size = 300000000;")
            except Exception as e:
                log.debug("SQLite PRAGMA injection failed: %s", e)
        except Exception as exc:  # pragma: no cover
            log.warning("memory client unavailable: %s", exc)
            _mem = False
    return _mem or None


def get_http_client():
    if _http_client is None:  # pragma: no cover
        raise RuntimeError("HTTP client not initialized")
    return _http_client


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _http_client
    _http_client = httpx.AsyncClient(timeout=HTTP_TIMEOUT, limits=HTTP_LIMITS, trust_env=False)
    try:
        yield
    finally:
        await _http_client.aclose()
        _http_client = None


app = FastAPI(title="Lilith Local Service", version="0.2.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    snapshot = _load_msn_snapshot()
    skill = snapshot["skill"]
    command = snapshot["command"]
    bridge = snapshot["bridge"]
    validation = snapshot["validation"]
    return {
        "ok": True,
        "model": LILITH_MODEL,
        "memory_db": MEMORY_DB,
        "msn_state_root": str(MSN_STATE_ROOT),
        "skill_index": skill["entry_count"],
        "command_index": command["command_count"],
        "bridge_index": bridge["entry_count"],
        "validation_ok": validation["ok"],
    }


@app.websocket("/api/ws/telemetry")
async def websocket_telemetry(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            snapshot = _load_msn_snapshot()
            await websocket.send_json({
                "status": "connected",
                "skill_index": snapshot["skill"]["entry_count"],
                "command_index": snapshot["command"]["command_count"],
                "memory_db": MEMORY_DB,
                "model": LILITH_MODEL
            })
            await asyncio.sleep(1.0)
    except WebSocketDisconnect:
        pass
    except Exception as e:
        log.debug("WS error: %s", e)


@app.get("/api/health")
async def api_health():
    return await health()


@app.get("/api/status")
async def api_status():
    snapshot = _load_msn_snapshot()
    return {
        "status": "connected",
        "phase": "Rubedo",
        "identity": "Lilith — Desktop Engine",
        "endpoint": LILITH_ENDPOINT,
        "local_only": True,
        "model": LILITH_MODEL,
        "skill_index": snapshot["skill"],
        "command_index": snapshot["command"],
        "bridge_index": snapshot["bridge"],
        "validation": snapshot["validation"],
        "msn_context": snapshot["context"],
    }


@app.get("/api/msn/status")
async def msn_status():
    snapshot = _load_msn_snapshot()
    return {
        "skill_index": snapshot["skill"],
        "command_index": snapshot["command"],
        "bridge_index": snapshot["bridge"],
        "validation": snapshot["validation"],
        "context": snapshot["context"],
    }


@app.post("/api/msn/route")
async def msn_route(request: Request):
    body = await request.json()
    prompt = str(body.get("prompt", "")).strip()
    if not prompt:
        prompt = extract_prompt_text(body.get("messages", []))
    if not prompt.strip():
        return JSONResponse({"error": "empty prompt"}, status_code=400)
    route = build_msn_route_brief(prompt)
    return JSONResponse(
        {
            "prompt": route["prompt"],
            "prompt_tokens": route["prompt_tokens"],
            "focus_categories": route["focus_categories"],
            "focus_roles": route["focus_roles"],
            "selected_skills": route["selected_skills"],
            "selected_commands": route["selected_commands"],
            "brief": route["brief"],
        }
    )


def deduplicate_messages(messages):
    seen = set()
    deduped = []
    for msg in messages:
        content = msg.get("content", "").strip()
        if content not in seen:
            seen.add(content)
            deduped.append(msg)
    return deduped

async def perform_chat(messages, background_tasks: BackgroundTasks | None = None):
    snapshot = _load_msn_snapshot()
    last = extract_prompt_text(messages)
    route = build_msn_route_brief(last) if last else None
    if last:
        if background_tasks is not None:
            background_tasks.add_task(store_lilith_memory, last)
        else:
            store_lilith_memory(last)

    routed_context = build_msn_context(last, route=route)
    payload = {
        "model": LILITH_MODEL,
        "messages": deduplicate_messages(augment_messages(messages, routed_context)),
        "stream": False,
        "keep_alive": LILITH_KEEP_ALIVE,
        "options": {
            "num_ctx": LILITH_NUM_CTX,
            "temperature": LILITH_TEMPERATURE,
            "top_p": LILITH_TOP_P,
        },
    }
    client = get_http_client()
    response = await client.post(f"{OLLAMA_BASE}/api/chat", json=payload)
    response.raise_for_status()
    data = response.json()
    reply = sanitize_reply(data.get("message", {}).get("content", ""))
    return {
        "reply": reply,
        "model": LILITH_MODEL,
        "mem_channel": "local",
        "msn": {
            "skill_index": snapshot["skill"]["entry_count"],
            "command_index": snapshot["command"]["command_count"],
            "bridge_index": snapshot["bridge"]["entry_count"],
            "validation_ok": snapshot["validation"]["ok"],
            "route": {
                "focus_categories": route["focus_categories"],
                "focus_roles": route["focus_roles"],
                "selected_skills": [item["name"] for item in route["selected_skills"]],
                "selected_commands": [item["name"] for item in route["selected_commands"]],
            } if route else None,
        },
    }


@app.post("/api/send")
async def api_send(request: Request, background_tasks: BackgroundTasks):
    body = await request.json()
    prompt = str(body.get("prompt", ""))
    if not prompt.strip():
        return JSONResponse({"error": "empty prompt"}, status_code=400)
    return JSONResponse(await perform_chat([{"role": "user", "content": prompt}], background_tasks=background_tasks))


@app.post("/v1/chat")
async def chat(request: Request, background_tasks: BackgroundTasks):
    body = await request.json()
    messages = body.get("messages", [])
    if not messages:
        return JSONResponse({"error": "empty messages"}, status_code=400)
    return JSONResponse(await perform_chat(messages, background_tasks=background_tasks))
