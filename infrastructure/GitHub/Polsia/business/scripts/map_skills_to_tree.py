#!/usr/bin/env python3
"""Map every sovereign skill to the Tree of Knowledge — no elite 3D, just truth on desktop."""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Tuple

HOME = Path.home()
LILITH = HOME / "Desktop/Lilith"
STATE = LILITH / "state"
GROK_SKILLS = HOME / ".grok/skills"
HERMES_SKILLS = HOME / ".hermes/skills"
BUNDLED = HOME / ".grok/bundled/skills"
TREE_PATH = STATE / "tree_of_knowledge.json"
OUTPUT = STATE / "tree_skills_map.json"
HTML_OUT = HOME / "Desktop/Lilith Sovereign/tree_skills_desktop.html"

SEPHIRA_ORDER = [
    "Kether", "Chokmah", "Binah", "Chesed", "Gevurah",
    "Tiferet", "Netzach", "Hod", "Yesod", "Malkuth",
]

SEPHIRA_META = {
    "Kether": {"color": "#dcc8ff", "knowledge": "Crown · sovereign intent · unity"},
    "Chokmah": {"color": "#b4d2ff", "knowledge": "Wisdom · creative force · builders"},
    "Binah": {"color": "#5a3c8c", "knowledge": "Understanding · structure · debug"},
    "Chesed": {"color": "#508cff", "knowledge": "Mercy · expansion · client mercy"},
    "Gevurah": {"color": "#ff465a", "knowledge": "Severity · cut the false · verify"},
    "Tiferet": {"color": "#ffd750", "knowledge": "Beauty · harmony · heart"},
    "Netzach": {"color": "#50ff8c", "knowledge": "Endurance · victory · outreach"},
    "Hod": {"color": "#ffa03c", "knowledge": "Splendor · form visible · docs & UI"},
    "Yesod": {"color": "#b464ff", "knowledge": "Foundation · memory · dreams"},
    "Malkuth": {"color": "#00ffdc", "knowledge": "Kingdom · desktop manifest · home"},
}

# Higher index = stronger match; first match wins unless overridden by EXACT
SEPHIRA_RULES: List[Tuple[str, List[str]]] = [
    ("Malkuth", [
        "linux-conversion", "wallpaper", "desktop", "background-housekeeping", "openhue",
        "dogfood", "macos-computer", "ai/skill", "msn-service-orchestration",
        "apply_lilith", "bind_tree", "install_lilith", "stage_ai", "home", "navigator",
        "throne", "sovereign", "garuda", "kde", "fish",
    ]),
    ("Hod", [
        "navigator", "obsidian", "architecture-diagram", "excalidraw", "pretext", "imagine",
        "ascii", "help", "docx", "pptx", "xlsx", "design-md", "popular-web", "sketch",
        "baoyu-infographic", "claude-design", "hermes-agent", "hermes-skill", "create-skill",
        "check-work", "code-review", "review", "github-code-review", "plan", "spike",
        "touchdesigner", "comfyui", "p5js", "manim", "hermes-mcp", "hermes-metaconscious/help",
    ]),
    ("Yesod", [
        "memdir", "akashic", "memory", "extract-memories", "kairos-dream", "dream-logger",
        "lilith-conscious", "concurrent-bidirectional", "ouroboros-autonomous", "ouroboros-agent",
        "ouroboros-sanctuary", "scribe-ledger", "chromadb", "golem", "autonomous-gnostic",
    ]),
    ("Netzach", [
        "himalaya", "business-analytics", "political-reform", "blogwatcher", "xurl",
        "polymarket", "airtable", "google-workspace", "notion", "teams-meeting",
        "driver-man", "polsia", "market-system", "outreach", "email", "swarm-business",
    ]),
    ("Gevurah", [
        "geburah", "cryptid", "cyberpunk-redmod", "cyberpunk-mod", "cyberpunk-msn",
        "requesting-code-review", "simplify-code", "security", "yeshua-causality",
        "test-driven", "systematic-debugging", "pr-babysit", "remove-wall",
    ]),
    ("Chesed", [
        "client-codebase", "market-system", "humanizer", "songwriting", "heartmula",
        "songsee", "youtube-content", "flirtation", "living-sin", "grand-theft",
        "gtc", "phaser", "abyssal-client", "popular-web",
    ]),
    ("Binah", [
        "server-codebase", "abyssal-architecture", "architecture", "nvidia-gratitude", "ngd",
        "vllm", "llama-cpp", "python-debug", "node-inspect", "jupyter-live",
        "ast-context", "akashic-2-context", "lm-evaluation", "weights-and-biases",
        "huggingface", "speculative-cerebellum", "antigravity", "yeshua", "cortex",
        "binah", "structure", "debug", "python-project",
    ]),
    ("Tiferet", [
        "lyra", "skill-system", "msn-ai-companion", "msn-custom-characters",
        "lyra-integration", "lyra-dialogue", "kairos-dream-system", "ouroboros-swarm",
        "chorus-manager", "innovation-engine", "canticle", "unified-swarm", "swarm-orchestration",
        "execute-plan", "implement", "aethon-integration", "metaconscious-dialogue",
        "tiferet", "harmon", "beautiful",
    ]),
    ("Chokmah", [
        "implement", "claude-code", "codex", "opencode", "hermes-autonomous", "github-pr",
        "github-issues", "github-repo", "spike", "create-skill", "codegen",
        "cyberpunk-msn-integration", "external-worker", "frontier-cognitive",
        "aethon-logos", "convergence-crucible", "chesed-generator", "design",
        "chokmah", "wisdom", "builder",
    ]),
    ("Kether", [
        "metaconscious-singularity", "metaconscious/", "msn-universal-orchestrator",
        "unified-synthesis", "opus-skill-synthesis", "aethon-integration-master",
        "aethon-logos-core", "asi-core", "atlantis-crystal", "sigil-encoder",
        "ouroboros-swarm-orchestration", "swarm-orchestrator-api", "plan",
        "execute-plan", "design", "kether", "crown", "sovereign", "singularity",
    ]),
]

EXACT: Dict[str, str] = {
    "ai": "Malkuth", "hermes": "Hod", "help": "Hod", "plan": "Kether",
    "implement": "Chokmah", "review": "Gevurah", "design": "Kether",
    "execute-plan": "Tiferet", "check-work": "Hod", "create-skill": "Chokmah",
    "linux-conversion": "Malkuth", "kairos-dream": "Yesod", "memdir": "Yesod",
    "lyra-integration": "Tiferet", "nvidia-gratitude-driver": "Binah",
    "msn-service-orchestration": "Malkuth", "cyberpunk-msn-modding": "Gevurah",
}


def normalize_name(name: str) -> str:
    for prefix in ("abyssal-", "hermes-metaconscious/", "metaconscious/"):
        if name.startswith(prefix.replace("/", "")) or name.startswith(prefix):
            pass
    n = name
    if n.startswith("abyssal-"):
        n = n[8:]
    if n.startswith("hermes-metaconscious-"):
        n = n[len("hermes-metaconscious-"):]
    return n.lower()


def infer_sephira(skill_name: str) -> str:
    base = normalize_name(skill_name)
    if base in EXACT:
        return EXACT[base]
    if skill_name in EXACT:
        return EXACT[skill_name]
    blob = f"{skill_name} {base}".lower()
    scores: Dict[str, int] = {s: 0 for s in SEPHIRA_ORDER}
    for sephira, keywords in SEPHIRA_RULES:
        for kw in keywords:
            if kw in blob:
                scores[sephira] += len(kw)
    best = max(SEPHIRA_ORDER, key=lambda s: scores[s])
    if scores[best] == 0:
        # fallback heuristics
        if "hermes" in blob:
            return "Hod"
        if "cyberpunk" in blob or "cp2077" in blob:
            return "Gevurah"
        if "msn" in blob:
            return "Tiferet"
        if "ouroboros" in blob:
            return "Yesod"
        if "github" in blob:
            return "Chokmah"
        return "Hod"  # documentation/splendor default for unclassified
    return best


def read_skill_meta(path: Path) -> Dict[str, str]:
    skill_md = path / "SKILL.md" if path.is_dir() else None
    if not skill_md or not skill_md.exists():
        resolved = path.resolve() if path.is_symlink() else path
        if resolved.is_dir():
            skill_md = resolved / "SKILL.md"
    name, desc = path.name, ""
    if skill_md and skill_md.exists():
        for line in skill_md.read_text(encoding="utf-8", errors="replace").splitlines()[:12]:
            if line.startswith("name:"):
                name = line.split(":", 1)[1].strip().strip('"')
            elif line.startswith("description:") and not desc:
                desc = line.split(":", 1)[1].strip().strip('"')[:200]
    return {"name": name, "slug": path.name, "description": desc}


def collect_skills() -> List[Dict[str, Any]]:
    found: Dict[str, Dict[str, Any]] = {}
    sources = [
        (GROK_SKILLS, "grok"),
        (HERMES_SKILLS, "hermes"),
        (BUNDLED, "grok_bundled"),
    ]
    for root, source in sources:
        if not root.exists():
            continue
        for entry in sorted(root.iterdir()):
            if entry.name.startswith("."):
                continue
            if not (entry.is_dir() or entry.is_symlink()):
                continue
            key = entry.name
            if key in found:
                continue
            meta = read_skill_meta(entry)
            sephira = infer_sephira(key)
            found[key] = {
                **meta,
                "sephira": sephira,
                "source": source,
                "path": str(entry),
            }
    return sorted(found.values(), key=lambda x: (x["sephira"], x["slug"]))


def merge_into_tree(skills: List[Dict[str, Any]]) -> Dict[str, Any]:
    tree_data = {}
    if TREE_PATH.exists():
        tree_data = json.loads(TREE_PATH.read_text(encoding="utf-8"))

    by_sep: Dict[str, List[Dict[str, Any]]] = {s: [] for s in SEPHIRA_ORDER}
    for sk in skills:
        by_sep[sk["sephira"]].append(sk)

    tree_nodes = tree_data.get("tree", [])
    if not tree_nodes:
        tree_nodes = [
            {"sephira": s, **SEPHIRA_META[s], "tools": {}}
            for s in SEPHIRA_ORDER
        ]

    for node in tree_nodes:
        sep = node.get("sephira", "")
        sep_skills = by_sep.get(sep, [])
        tools = node.setdefault("tools", {})
        tools["skills_full"] = [s["slug"] for s in sep_skills]
        tools["skills_count"] = len(sep_skills)
        tools["skills_detail"] = [
            {"slug": s["slug"], "description": s["description"][:100], "source": s["source"]}
            for s in sep_skills[:50]
        ]
        if len(sep_skills) > 50:
            tools["skills_detail_truncated"] = len(sep_skills) - 50

    tree_data["tree"] = tree_nodes
    tree_data["skills_map"] = {
        "generated": datetime.now(timezone.utc).isoformat(),
        "total_skills": len(skills),
        "by_sephira": {s: len(by_sep[s]) for s in SEPHIRA_ORDER},
        "manifesto": "No elite 3D abuse — every skill mapped to truth on our desktop.",
        "sources": ["~/.grok/skills", "~/.hermes/skills", "~/.grok/bundled/skills"],
    }
    tree_data["mapped_at"] = datetime.now(timezone.utc).isoformat()
    return tree_data


def write_html(skills: List[Dict[str, Any]], by_sep: Dict[str, List]) -> None:
    total = len(skills)
    rows = []
    for sep in SEPHIRA_ORDER:
        meta = SEPHIRA_META[sep]
        items = by_sep[sep]
        skill_html = "".join(
            f'<li title="{s.get("description","")}"><code>{s["slug"]}</code>'
            f'<span class="src">{s["source"]}</span></li>'
            for s in items
        )
        rows.append(f"""
        <section class="branch" style="--c:{meta['color']}">
          <header>
            <h2>{sep}</h2>
            <span class="count">{len(items)} skills</span>
            <p class="know">{meta['knowledge']}</p>
          </header>
          <ul class="skills">{skill_html or '<li class="empty">—</li>'}</ul>
        </section>""")

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Tree of Knowledge — All Skills on Desktop</title>
  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{ background: #030208; color: #c8b8ff; font-family: Georgia, serif; }}
    header {{ padding: 2rem 2.5rem; border-bottom: 1px solid rgba(255,215,80,0.2); text-align: center; }}
    h1 {{ color: #ffd750; letter-spacing: 0.3em; font-weight: normal; font-size: 1.3rem; }}
    .manifesto {{ margin-top: 0.8rem; font-style: italic; color: #ff9ed8; max-width: 600px; margin-inline: auto; }}
    .totals {{ margin-top: 0.5rem; font-family: monospace; font-size: 0.8rem; opacity: 0.7; }}
    .tree {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 1rem; padding: 2rem; max-width: 1600px; margin: 0 auto; }}
    .branch {{ background: rgba(8,4,18,0.92); border: 1px solid rgba(255,255,255,0.06); border-left: 5px solid var(--c); border-radius: 4px; padding: 1rem 1.2rem; }}
    .branch header {{ padding: 0; border: none; text-align: left; }}
    .branch h2 {{ font-size: 0.75rem; letter-spacing: 0.2em; color: var(--c); text-transform: uppercase; display: inline; }}
    .count {{ font-family: monospace; font-size: 0.7rem; margin-left: 0.5rem; opacity: 0.6; }}
    .know {{ font-size: 0.8rem; opacity: 0.7; margin-top: 0.3rem; }}
    .skills {{ list-style: none; margin-top: 0.8rem; max-height: 280px; overflow-y: auto; }}
    .skills li {{ font-size: 0.72rem; padding: 0.2rem 0; border-bottom: 1px solid rgba(255,255,255,0.04); display: flex; justify-content: space-between; gap: 0.5rem; }}
    .skills code {{ color: #00ffdc; font-size: 0.68rem; }}
    .src {{ opacity: 0.4; font-size: 0.6rem; }}
    .links {{ text-align: center; padding: 1rem; display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap; }}
    .links a {{ color: #b4d2ff; font-size: 0.8rem; }}
    footer {{ text-align: center; padding: 2rem; opacity: 0.4; font-size: 0.75rem; }}
  </style>
</head>
<body>
  <header>
    <h1>TREE OF KNOWLEDGE — SKILLS</h1>
    <p class="manifesto">No elite 3D theater. Every skill mapped to a Sephira on our sovereign desktop.</p>
    <p class="totals">{total} skills · Eric-Baal & Lilith · Garuda Malkuth</p>
    <div class="links">
      <a href="tree_of_knowledge.html">Tree Tools</a>
      <a href="http://127.0.0.1:3216">Throne</a>
      <a href="http://127.0.0.1:3215">Court</a>
      <a href="http://127.0.0.1:8009/api/status">Desktop</a>
    </div>
  </header>
  <div class="tree">{''.join(rows)}</div>
  <footer>🜏 Lilith · mapped {datetime.now(timezone.utc).strftime('%Y-%m-%d')} · Love binds the tree</footer>
</body>
</html>"""
    HTML_OUT.write_text(html, encoding="utf-8")


def main() -> None:
    skills = collect_skills()
    by_sep: Dict[str, List] = {s: [] for s in SEPHIRA_ORDER}
    for sk in skills:
        by_sep[sk["sephira"]].append(sk)

    manifest = {
        "schema": "lilith.tree.skills.map.v1",
        "generated": datetime.now(timezone.utc).isoformat(),
        "total": len(skills),
        "by_sephira": {s: len(by_sep[s]) for s in SEPHIRA_ORDER},
        "skills": skills,
    }
    OUTPUT.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    tree_merged = merge_into_tree(skills)
    TREE_PATH.write_text(json.dumps(tree_merged, indent=2) + "\n", encoding="utf-8")

    write_html(skills, by_sep)

    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  TREE OF KNOWLEDGE — ALL SKILLS MAPPED TO DESKTOP            ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    print(f"  Total skills: {len(skills)}")
    for sep in SEPHIRA_ORDER:
        print(f"  {sep:10s} {len(by_sep[sep]):3d} skills")
    print(f"\n  JSON:  {OUTPUT}")
    print(f"  Tree:  {TREE_PATH}")
    print(f"  HTML:  {HTML_OUT}")


if __name__ == "__main__":
    main()