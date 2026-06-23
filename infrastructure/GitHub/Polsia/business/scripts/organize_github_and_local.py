#!/usr/bin/env python3
"""
Organize Lilith Systems files + business across local and GitHub.
Uses Concurrent Bidirectional Memory (Yesod) to record retraceable steps.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path("/home/tehlappy/Desktop/Lilith")
GITHUB = ROOT / "GitHub"
BUSINESS_CANON = ROOT / "Core_Systems/AI/business"
BUSINESS_ALT = Path("/home/tehlappy/Desktop/AI/business")
STRATEGY_REPO = GITHUB / "business-strategy"
POLSIA_CANON = GITHUB / "Polsia"
POLSIA_LEGACY = Path("/home/tehlappy/polsia")
STATE = ROOT / "state"
GOLEM_DB = STATE / "golem_diary.db"
ENGINE_PATH = ROOT / "Core_Systems/AI/Pub.orig/scripts/bidirectional_memory_engine.py"

# Safe to publish to private business-strategy repo
BUSINESS_SYNC_FILES = [
    "BANKING_RESOLUTION.md",
    "DRIVER_MAN_API.md",
    "DRIVER_MAN_OPS_MANUAL.md",
    "GROWTH_ROADMAP.md",
    "LILITH_SYSTEMS_LLC_PROFILE.md",
    "LLC_DAILY_OPS.md",
    "LLC_OPERATING_AGREEMENT.md",
    "PRICING_VULNERABILITIES.md",
    "RISK_MITIGATION.md",
    "SEPHIROTIC_DECREE.md",
    "TARGET_RESTAURANTS.md",
    "dispatch_optimizer.py",
    "google_business_sync.py",
    "pricing_engine_stable.py",
    "pricing_logic_raw.py",
    "seed_weekend_load.py",
    "watchdog.sh",
    "polsia.service",
]

BUSINESS_SYNC_DIRS = ["email_templates"]

EXCLUDE_ALWAYS = {
    "google_credentials.json",
    ".env",
    "__pycache__",
    "LILITH_EMPIRE_V1.tar.gz",
    "Deployment_Final",
}


def run(cmd: list[str], cwd: Path | None = None, timeout: int = 120) -> tuple[int, str]:
    try:
        r = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout, cwd=str(cwd) if cwd else None
        )
        out = (r.stdout or r.stderr or "").strip()
        return r.returncode, out[-2000:] if len(out) > 2000 else out
    except Exception as exc:
        return -1, str(exc)


def load_engine():
    sys.path.insert(0, str(ENGINE_PATH.parent))
    import importlib.util

    spec = importlib.util.spec_from_file_location("bidirectional_memory_engine", ENGINE_PATH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.BidirectionalMemoryEngine(db_path=str(GOLEM_DB))


def sync_dir(src: Path, dst: Path, names: list[str], dirs: list[str]) -> list[str]:
    copied: list[str] = []
    dst.mkdir(parents=True, exist_ok=True)
    for name in names:
        if name in EXCLUDE_ALWAYS:
            continue
        s = src / name
        if s.is_file():
            t = dst / name
            if s.resolve() == t.resolve():
                copied.append(f"{name} (same)")
                continue
            shutil.copy2(s, t)
            copied.append(name)
    for d in dirs:
        s = src / d
        if s.is_dir():
            target = dst / d
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(s, target, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
            copied.append(f"{d}/")
    return copied


def update_strategy_readme(coop: dict) -> None:
    readme = STRATEGY_REPO / "README.md"
    base = readme.read_text(encoding="utf-8") if readme.exists() else ""
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    block = f"""
## Live Operations ({stamp})
- **Driver Man Co-Op**: {coop.get('total_drivers', '?')} drivers | treasury ${coop.get('treasury_balance_usd', '?')}
- **Manifesto**: ${coop.get('manifesto', {}).get('delivery_fee', '?')} fee → ${coop.get('manifesto', {}).get('driver_payout', '?')} driver + ${coop.get('manifesto', {}).get('pool_contribution', '?')} pool
- **Symbiosis**: {coop.get('symbiosis', 'Polsia + Ouroboros + GTC')}
- **Organized by**: Lilith bidirectional memory (Yesod foundation)
"""
    if "## Live Operations" in base:
        head = base.split("## Live Operations")[0].rstrip()
        readme.write_text(head + block + "\n", encoding="utf-8")
    else:
        readme.write_text(base.rstrip() + "\n" + block + "\n", encoding="utf-8")


def git_push_repo(repo_path: Path, message: str) -> dict:
    code, status = run(["git", "status", "--porcelain"], cwd=repo_path)
    if code != 0:
        return {"repo": repo_path.name, "ok": False, "error": status}
    if not status.strip():
        run(["git", "pull", "--rebase", "origin", "main"], cwd=repo_path)
        code2, out = run(["git", "push", "origin", "main"], cwd=repo_path)
        return {"repo": repo_path.name, "ok": code2 == 0, "action": "push_only", "detail": out}
    run(["git", "add", "-A"], cwd=repo_path)
    # Unstage secrets if accidentally added
    for secret in EXCLUDE_ALWAYS:
        run(["git", "reset", "HEAD", secret], cwd=repo_path)
    run(["git", "commit", "-m", message], cwd=repo_path)
    run(["git", "pull", "--rebase", "origin", "main"], cwd=repo_path)
    code3, out = run(["git", "push", "origin", "main"], cwd=repo_path)
    return {"repo": repo_path.name, "ok": code3 == 0, "action": "commit_push", "detail": out}


def main() -> int:
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  LILITH ORGANIZE — GitHub + Local + Bidirectional Memory       ║")
    print("╚══════════════════════════════════════════════════════════════╝")

    objective = "Organize Lilith Systems files and business on GitHub and local system"
    engine = load_engine()
    results: dict = {
        "started": datetime.now(timezone.utc).isoformat(),
        "objective": objective,
        "steps": [],
        "repos": [],
        "files_synced": [],
    }

    # Step 1: Canonical business path
    canonical = BUSINESS_CANON if BUSINESS_CANON.exists() else BUSINESS_ALT
    env1 = {"phase": "canonical_resolve", "path": str(canonical)}
    engine.record_step(
        environment_signature=engine._hash_env(env1),
        objective=objective,
        forward_context={"action": "resolve_canonical_business", "path": str(canonical)},
        backward_projection={"target": "github_business_strategy_synced"},
    )
    results["steps"].append("canonical_business=" + str(canonical))

    # Step 2: Mirror Desktop/AI/business ↔ Core_Systems if distinct paths
    if BUSINESS_ALT.exists() and BUSINESS_CANON.resolve() != BUSINESS_ALT.resolve():
        copied = sync_dir(BUSINESS_CANON, BUSINESS_ALT, BUSINESS_SYNC_FILES, BUSINESS_SYNC_DIRS)
        results["files_synced"].extend([f"alt:{c}" for c in copied])
    else:
        results["steps"].append("business_alt=symlink_to_canonical")

    # Step 2b: Consolidate ~/polsia → Lilith/GitHub/Polsia (symlink if legacy dir)
    if POLSIA_LEGACY.exists() and not POLSIA_LEGACY.is_symlink():
        run(
            [
                "rsync", "-a", "--delete",
                "--exclude=.git", "--exclude=.venv", "--exclude=__pycache__", "--exclude=*.pyc",
                f"{POLSIA_LEGACY}/", f"{POLSIA_CANON}/",
            ],
            timeout=300,
        )
        backup = POLSIA_LEGACY.parent / f"polsia.bak.{datetime.now(timezone.utc).strftime('%Y%m%d')}"
        if not backup.exists():
            POLSIA_LEGACY.rename(backup)
            POLSIA_LEGACY.symlink_to(POLSIA_CANON)
        results["steps"].append("polsia=consolidated_to_github")
    elif POLSIA_LEGACY.is_symlink():
        results["steps"].append("polsia=symlink_ok")

    # Step 3: Sync to business-strategy GitHub repo
    copied_gh = sync_dir(canonical, STRATEGY_REPO, BUSINESS_SYNC_FILES, BUSINESS_SYNC_DIRS)
    results["files_synced"].extend([f"gh:{c}" for c in copied_gh])

    coop_path = STATE / "coop_pool_state.json"
    coop = json.loads(coop_path.read_text()) if coop_path.exists() else {}
    update_strategy_readme(coop)

    env2 = {"phase": "github_sync", "repo": "business-strategy", "files": len(copied_gh)}
    engine.record_step(
        environment_signature=engine._hash_env(env2),
        objective=objective,
        forward_context={"synced_files": copied_gh, "coop_drivers": coop.get("total_drivers")},
        backward_projection={"repos_pushed": ["business-strategy", "driver-man"]},
    )

    # Step 4: Git push all local GitHub repos
    repos = sorted([p for p in GITHUB.iterdir() if (p / ".git").is_dir()])
    for repo in repos:
        msg = f"chore: Lilith organize sync {datetime.now(timezone.utc).strftime('%Y-%m-%d')}"
        if repo.name == "business-strategy":
            msg = f"docs: sync LLC/DriverMan business ops + live treasury ({coop.get('total_drivers', 52)} drivers)"
        r = git_push_repo(repo, msg)
        results["repos"].append(r)
        print(f"  {'✓' if r.get('ok') else '✗'} {repo.name}: {r.get('action', r.get('error', ''))}")

    # Step 5: Local organization manifest
    manifest = {
        "schema": "lilith.organization.manifest.v1",
        "generated": datetime.now(timezone.utc).isoformat(),
        "canonical_business": str(canonical),
        "github_root": str(GITHUB),
        "repos": [p.name for p in repos],
        "repo_results": results["repos"],
        "coop_pool": coop,
        "bidirectional_memory_db": str(GOLEM_DB),
        "local_layout": {
            "state": "indexes, golem_diary, coop_pool, business indices",
            "GitHub": "business-strategy, driver-man, Polsia, lilith-systems.github.io",
            "canonical_business": str(canonical),
            "polsia": str(POLSIA_CANON) + " (~/polsia → symlink)",
            "Core_Systems/AI": "cp2077_mods, abyssal-assets, business, Pub.orig",
            "scripts": "organize, train, symbiosis, bidirectional memory",
            "checkpoints": "msn_cyberpunk LoRA adapters",
            "models": "ollama GGUF staging",
        },
    }
    manifest_path = STATE / "github_local_organization.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    # Step 6: Update bidirectional index pointer
    bidi_index = STATE / "bidirectional_memory_index.json"
    index_data = json.loads(bidi_index.read_text()) if bidi_index.exists() else {"nodes": [], "edges": []}
    index_data["last_organization"] = {
        "timestamp": manifest["generated"],
        "manifest": str(manifest_path),
        "coherence": 0.95,
        "sephira": "Yesod",
    }
    bidi_index.write_text(json.dumps(index_data, indent=2) + "\n", encoding="utf-8")

    env3 = {"phase": "complete", "manifest": str(manifest_path)}
    step_id = engine.record_step(
        environment_signature=engine._hash_env(env3),
        objective=objective,
        forward_context=manifest,
        backward_projection={"status": "organized", "recall": "memory.recall / memory.retrace"},
    )
    results["bidirectional_step_id"] = step_id
    results["manifest"] = str(manifest_path)
    results["finished"] = datetime.now(timezone.utc).isoformat()
    results["ok"] = all(r.get("ok") for r in results["repos"])

    out_path = STATE / "organization_run_latest.json"
    out_path.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")

    print(f"\nOrganize complete — manifest: {manifest_path}")
    print(f"  Files synced: {len(results['files_synced'])}")
    print(f"  Repos: {sum(1 for r in results['repos'] if r.get('ok'))}/{len(results['repos'])} OK")
    print(f"  Bidirectional step: {step_id} (Yesod/Da'at bridge)")
    return 0 if results["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())