#!/usr/bin/env python3
import os
import json
from pathlib import Path

# Paths to scan
PATHS = {
    "Pub": "/home/tehlappy/Desktop/AI/Pub",
    "Invite": "/home/tehlappy/invite",
    "Hermes": "/home/tehlappy/.hermes/hermes-agent",
    "Skills": "/home/tehlappy/.agents/skills"
}

# Excluded patterns
EXCLUDE_DIRS = {
    ".git", ".venv", "venv", ".venv-pub", "node_modules", "__pycache__", 
    ".cache", "dist", "build", "vkd3d-proton.cache", "grokdata_extracted", 
    "reports", "docs-internal", "docs-public", "infra-terraform", 
    "infra-kubernetes", "codex-desktop-linux", ".cargo", ".rustup", "target"
}

EXCLUDE_EXTENSIONS = {
    ".zip", ".gz", ".tar", ".bin", ".iso", ".png", ".jpg", ".jpeg", 
    ".gif", ".ico", ".pdf", ".sqlite", ".db", ".exe", ".dll", ".so", 
    ".obj", ".cache", ".pdb"
}

def get_file_lang(extension: str) -> str:
    lang_map = {
        ".py": "python",
        ".js": "javascript",
        ".ts": "typescript",
        ".tsx": "typescript",
        ".jsx": "javascript",
        ".cjs": "javascript",
        ".mjs": "javascript",
        ".rs": "rust",
        ".html": "html",
        ".css": "css",
        ".sh": "bash",
        ".bash": "bash",
        ".fish": "fish",
        ".toml": "toml",
        ".yaml": "yaml",
        ".yml": "yaml",
        ".json": "json",
        ".md": "markdown",
        ".reds": "redscript",
        ".tweak": "tweakdb"
    }
    return lang_map.get(extension.lower(), "text")

def scan_codebase() -> list:
    dataset = []
    file_count = 0
    total_bytes = 0

    print("Starting codebase scan for dataset generation...")

    for project_name, project_path in PATHS.items():
        base_path = Path(project_path)
        if not base_path.exists():
            print(f"Warning: Project path {project_path} for {project_name} does not exist. Skipping.")
            continue

        print(f"Scanning {project_name} at {project_path}...")
        for root, dirs, files in os.walk(base_path, followlinks=True):
            # Prune directory search
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith(".")]

            for file in files:
                file_path = Path(root) / file
                
                # Check exclusions
                if file.startswith(".") or file_path.suffix in EXCLUDE_EXTENSIONS:
                    continue

                try:
                    # Skip non-files (broken symlinks, sockets, directories)
                    if not os.path.isfile(file_path):
                        continue

                    # Skip files that are too large (e.g. > 500KB) to prevent context pollution
                    file_size = file_path.stat().st_size
                    if file_size > 500 * 1024:
                        continue

                    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()

                    # Ignore empty files
                    if not content.strip():
                        continue

                    rel_path = file_path.relative_to(base_path)
                    lang = get_file_lang(file_path.suffix)

                    # Formulate ShareGPT style prompt-response
                    prompt = f"Show me the source code and explain the purpose of file `{rel_path}` in the `{project_name}` codebase."
                    
                    explanation = f"This file is located at `{rel_path}` within the `{project_name}` project. "
                    if lang == "python":
                        explanation += "It contains Python execution or integration logic."
                    elif lang == "typescript" or lang == "javascript":
                        explanation += "It contains frontend or backend JS/TS logic."
                    elif lang == "redscript" or lang == "tweakdb":
                        explanation += "It defines a Cyberpunk 2077 game mod script or database configuration."
                    elif lang == "rust":
                        explanation += "It contains compiled Rust application logic."
                    elif lang == "markdown":
                        explanation += "It contains project documentation."
                    else:
                        explanation += "It contains configuration or structured data mappings."

                    response = f"{explanation}\n\n```{lang}\n{content}\n```"

                    dataset.append({
                        "conversations": [
                            {"from": "human", "value": prompt},
                            {"from": "gpt", "value": response}
                        ]
                    })
                    file_count += 1
                    total_bytes += len(content)

                except Exception as e:
                    # Print and continue
                    print(f"Error reading file {file_path}: {e}")

    print(f"Scan complete. Found {file_count} files, total size: {total_bytes / (1024*1024):.2f} MB.")
    return dataset

def main():
    output_dir = Path("/home/tehlappy/Desktop/Lilith/data")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    dataset = scan_codebase()
    output_path = output_dir / "codebase_dataset.json"
    
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(dataset, f, indent=2)
        
    print(f"Dataset successfully written to {output_path} ({len(dataset)} entries).")

if __name__ == "__main__":
    main()
