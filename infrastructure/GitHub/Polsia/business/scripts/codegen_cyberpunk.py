#!/usr/bin/env python3
"""Build MSN/Cyberpunk SFT dataset from game mod source files on D: and Desktop."""
import json
import os
from pathlib import Path

# MSN + GTC mod sources (priority order)
PATHS = {
    "msn_core": "/mnt/d/Cyberpunk/source/msn_core",
    "gtc_unified": "/mnt/d/Cyberpunk/source/gtc_unified",
    "msn_weapons": "/mnt/d/Cyberpunk/source/msn_weapons",
    "msn_story": "/mnt/d/Cyberpunk/source/msn_story",
    "abyssal_assets": "/mnt/d/Cyberpunk/source/abyssal_assets",
    "lochness": "/mnt/d/Cyberpunk/source/lochness",
    "lyra": "/mnt/d/Cyberpunk/source/lyra",
    "gtc_rebuild": "/mnt/d/Cyberpunk/source/gtc_rebuild",
    "gtc_items": "/mnt/d/Cyberpunk/source/gtc_items",
    "gtc_quests": "/mnt/d/Cyberpunk/source/gtc_quests",
    "gtc_space": "/mnt/d/Cyberpunk/source/gtc_space",
    "gtc_aethon_sync": "/mnt/d/Cyberpunk/source/gtc_aethon_sync_mods",
    "cp2077_mods": "/home/tehlappy/Desktop/Lilith/Core_Systems/AI/abyssal-assets/cp2077_mods",
    "gtc_bridge": "/mnt/d/Cyberpunk/bridge",
    "msn_router": "/home/tehlappy/Desktop/Lilith/Core_Systems/AI/abyssal-assets",
}

EXCLUDE_DIRS = {
    ".git", ".venv", "venv", ".venv-pub", "node_modules", "__pycache__",
    ".cache", "dist", "build", "client", "server", "shared",
}

EXCLUDE_EXTENSIONS = {
    ".zip", ".gz", ".tar", ".bin", ".iso", ".png", ".jpg", ".jpeg",
    ".gif", ".ico", ".pdf", ".sqlite", ".db", ".exe", ".dll", ".so",
    ".obj", ".cache", ".pdb", ".gguf", ".wav", ".mp3", ".mp4",
}

LANG_MAP = {
    ".py": "python", ".js": "javascript", ".ts": "typescript",
    ".reds": "redscript", ".tweak": "tweakdb", ".toml": "toml",
    ".yaml": "yaml", ".yml": "yaml", ".json": "json", ".md": "markdown",
    ".fish": "fish", ".sh": "bash",
}

PROMPTS = {
    "redscript": "Explain this REDscript component in the Grand Theft Cyberpunk MSN mod engine and how it integrates with Lilith/NGD:",
    "tweakdb": "Explain this TweakDB/mod manifest entry for the MSN Cyberpunk 2077 integration:",
    "python": "Explain this MSN orchestration Python module for the Cyberpunk mod engine:",
    "yaml": "Explain this MSN mod registry or deployment config for Grand Theft Cyberpunk:",
    "toml": "Explain this REDmod manifest for the MSN Cyberpunk mod stack:",
    "json": "Explain this GTC quest/item/data definition for the MSN game engine:",
    "markdown": "Summarize this MSN/Cyberpunk mod documentation for the local LLM engine:",
    "default": "Explain this file's role in the Metaconscious Singularity Node (MSN) Cyberpunk 2077 engine:",
}


def lang_for(path: Path) -> str:
    return LANG_MAP.get(path.suffix.lower(), "text")


def prompt_for(lang: str, rel: str, bundle: str) -> str:
    base = PROMPTS.get(lang, PROMPTS["default"])
    return f"{base} `{rel}` in bundle `{bundle}`."


def response_for(lang: str, rel: str, bundle: str, content: str) -> str:
    role = {
        "redscript": "REDscript game-side MSN listener/hook",
        "tweakdb": "TweakDB weapon/item/quest database entry",
        "python": "Lilith/GTC bridge orchestration code",
        "yaml": "mod registry or deploy manifest",
        "toml": "REDmod package definition",
        "json": "GTC content data (quests, items, NPCs)",
    }.get(lang, "MSN engine configuration")
    header = (
        f"File `{rel}` in `{bundle}` is a {role} for Grand Theft Cyberpunk. "
        f"It connects to Lilith (:3210), MSN Router (:8007), and the GTC bridge (:8766). "
        f"Local inference only — no cloud dependencies.\n\n"
    )
    return f"{header}```{lang}\n{content}\n```"


def scan() -> list:
    dataset = []
    seen = set()

    for bundle, root in PATHS.items():
        base = Path(root)
        if not base.exists():
            print(f"  skip (missing): {bundle} -> {root}")
            continue
        print(f"  scanning {bundle}...")
        count = 0
        for dirpath, dirs, files in os.walk(base, followlinks=True):
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith(".")]
            for fname in files:
                fp = Path(dirpath) / fname
                if fname.startswith(".") or fp.suffix in EXCLUDE_EXTENSIONS:
                    continue
                if not fp.is_file():
                    continue
                try:
                    if fp.stat().st_size > 400 * 1024:
                        continue
                    key = str(fp.resolve())
                    if key in seen:
                        continue
                    seen.add(key)
                    content = fp.read_text(encoding="utf-8", errors="ignore")
                    if not content.strip():
                        continue
                    rel = str(fp.relative_to(base))
                    lang = lang_for(fp)
                    dataset.append({
                        "conversations": [
                            {"from": "human", "value": prompt_for(lang, rel, bundle)},
                            {"from": "gpt", "value": response_for(lang, rel, bundle, content)},
                        ]
                    })
                    count += 1
                except OSError as exc:
                    print(f"    warn {fp}: {exc}")
        print(f"    +{count} files")

    return dataset


def main():
    out = Path("/home/tehlappy/Desktop/Lilith/data/msn_cyberpunk_dataset.json")
    out.parent.mkdir(parents=True, exist_ok=True)
    print("MSN Cyberpunk dataset generation")
    data = scan()
    out.write_text(json.dumps(data, indent=2), encoding="utf-8")
    print(f"Wrote {len(data)} entries -> {out}")


if __name__ == "__main__":
    main()