#!/usr/bin/env python3
"""
Organize business + Lilith state → GitHub repos and push all new content.
Extends organize_github_and_local.py with desktop/MSN/Cyberpunk artifacts.
"""
from __future__ import annotations

import json
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path.home() / "Desktop/Lilith"
GITHUB = ROOT / "GitHub"
STATE = ROOT / "state"
SCRIPTS = ROOT / "scripts"

# Artifacts to sync into repos
DESKTOP_EXPORTS = {
    "business-strategy": [
        ("state/coop_pool_state.json", "operations/coop_pool_state.json"),
        ("state/swarm_execution_report_1_40.json", "operations/swarm_report_phase1.json"),
        ("state/swarm_execution_report_41_60.json", "operations/swarm_report_phase2.json"),
        ("state/lilith_tool_orchestration.json", "operations/lilith_tool_orchestration.json"),
        ("state/quantum_skillset_desktop.json", "operations/quantum_skillset_desktop.json"),
        ("state/github_local_organization.json", "operations/github_organization.json"),
        ("state/cp2077_launch_checklist.md", "operations/cp2077_launch_checklist.md"),
        ("state/cp2077_smoke_test.json", "operations/cp2077_smoke_test.json"),
        ("state/abyssal_skill_bridge.json", "operations/abyssal_skill_bridge.json"),
    ],
    "driver-man": [
        ("state/coop_pool_state.json", "data/coop_pool_state.json"),
        ("Core_Systems/AI/business/DRIVER_MAN_API.md", "docs/DRIVER_MAN_API.md"),
        ("Core_Systems/AI/business/DRIVER_MAN_OPS_MANUAL.md", "docs/DRIVER_MAN_OPS_MANUAL.md"),
    ],
    "Polsia": [
        ("state/coop_pool_state.json", "data/coop_pool_state.json"),
        ("state/lilith_tool_orchestration.json", "config/lilith_tool_orchestration.json"),
    ],
    "lilith-systems.github.io": [
        ("state/quantum_skillset_desktop.json", "data/quantum_skillset.json"),
        ("Desktop/Lilith Sovereign/heart_mind.html", "heart_mind.html"),
    ],
}

EXCLUDE = {".env", "google_credentials.json", "__pycache__", ".git"}


def run(cmd: list, cwd: Path | None = None, timeout: int = 180) -> tuple[int, str]:
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, cwd=str(cwd) if cwd else None)
        return r.returncode, ((r.stdout or "") + (r.stderr or "")).strip()[-1500:]
    except Exception as e:
        return -1, str(e)


def sync_exports(repo_name: str, pairs: list[tuple[str, str]]) -> list[str]:
    repo = GITHUB / repo_name
    if not repo.is_dir():
        return []
    copied = []
    for src_rel, dst_rel in pairs:
        src = ROOT / src_rel if not src_rel.startswith("Desktop/") else Path.home() / src_rel
        if not src.exists():
            continue
        dst = repo / dst_rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        copied.append(dst_rel)
    return copied


def git_push(repo: Path, message: str) -> dict:
    code, status = run(["git", "status", "--porcelain"], cwd=repo)
    if code != 0:
        return {"repo": repo.name, "ok": False, "error": status}
    if not status.strip():
        _, br = run(["git", "branch", "--show-current"], cwd=repo)
        branch = br.strip() or "main"
        code2, out = run(["git", "push", "origin", branch], cwd=repo)
        return {"repo": repo.name, "ok": code2 == 0, "action": "push_only", "detail": out}
    run(["git", "add", "-A"], cwd=repo)
    for secret in EXCLUDE:
        run(["git", "reset", "HEAD", secret], cwd=repo)
    run(["git", "commit", "-m", message], cwd=repo)
    _, branches = run(["git", "branch", "--show-current"], cwd=repo)
    branch = branches.strip() or "main"
    run(["git", "pull", "--rebase", f"origin", branch], cwd=repo)
    code3, out = run(["git", "push", "origin", branch], cwd=repo)
    return {"repo": repo.name, "ok": code3 == 0, "action": "commit_push", "detail": out}


def clone_or_update_remote(org_repo: str, local_name: str) -> Path | None:
    """Clone Lilith-Systems repos we don't have locally for content push."""
    target = GITHUB / local_name
    if target.exists() and (target / ".git").is_dir():
        run(["git", "pull", "--rebase", "origin", "main"], cwd=target)
        return target
    code, out = run(["gh", "repo", "clone", f"Lilith-Systems/{org_repo}", str(target)], timeout=120)
    return target if code == 0 and target.exists() else None


def push_msn_integration_snapshot() -> dict:
    """Push desktop state README to msn-integration repo."""
    repo = clone_or_update_remote("msn-integration", "msn-integration")
    if not repo:
        return {"repo": "msn-integration", "ok": False, "error": "clone failed"}
    ops = repo / "operations"
    ops.mkdir(exist_ok=True)
    for src_name in ("swarm_execution_report_1_40.json", "lilith_tool_orchestration.json",
                     "quantum_skillset_desktop.json", "cp2077_launch_checklist.md"):
        src = STATE / src_name
        if src.exists():
            shutil.copy2(src, ops / src_name)
    readme_add = f"""
## Desktop Sync ({datetime.now(timezone.utc).strftime('%Y-%m-%d')})
- Swarm execution reports staged in `operations/`
- Tool orchestration + quantum skillset manifests
- Launch checklist for Garuda/Proton REDmod
"""
    readme = repo / "README.md"
    base = readme.read_text(encoding="utf-8") if readme.exists() else "# MSN Integration\n"
    if "## Desktop Sync" not in base:
        readme.write_text(base.rstrip() + readme_add, encoding="utf-8")
    return git_push(repo, f"chore: sync Lilith desktop operations {datetime.now(timezone.utc).strftime('%Y-%m-%d')}")


def main() -> int:
    print("=== ORGANIZE BUSINESS + GITHUB PUSH ===")
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    # Run base organize script first
    run(["python3", str(SCRIPTS / "organize_github_and_local.py")], timeout=300)

    exports_log: dict = {}
    for repo_name, pairs in DESKTOP_EXPORTS.items():
        copied = sync_exports(repo_name, pairs)
        exports_log[repo_name] = copied
        print(f"  {repo_name}: {len(copied)} files exported")

    # Push local repos
    push_results = []
    for repo in sorted(GITHUB.iterdir()):
        if not (repo / ".git").is_dir():
            continue
        msg = f"chore: Lilith organize + desktop ops sync {stamp}"
        if repo.name == "business-strategy":
            msg = f"docs: business ops + swarm reports + orchestration {stamp}"
        r = git_push(repo, msg)
        push_results.append(r)
        print(f"  {'✓' if r.get('ok') else '✗'} {r['repo']}: {r.get('action', r.get('error', ''))}")

    # Remote repos not in local GitHub folder
    for remote in ("msn-integration", "grand-theft-cyberpunk"):
        if remote == "msn-integration":
            r = push_msn_integration_snapshot()
        else:
            repo = clone_or_update_remote(remote, remote)
            if repo:
                ops = repo / "operations"
                ops.mkdir(exist_ok=True)
                for f in ("swarm_execution_report_1_40.json", "quantum_skillset_desktop.json"):
                    s = STATE / f
                    if s.exists():
                        shutil.copy2(s, ops / f)
                r = git_push(repo, f"chore: desktop state sync {stamp}")
            else:
                r = {"repo": remote, "ok": False, "error": "clone failed"}
        push_results.append(r)
        print(f"  {'✓' if r.get('ok') else '✗'} {r['repo']}")

    # Seal phase 2
    phase2 = {
        "schema": "lilith.swarm.phase2.complete.v1",
        "completed_at": datetime.now(timezone.utc).isoformat(),
        "exports": exports_log,
        "push_results": push_results,
        "repos_ok": sum(1 for r in push_results if r.get("ok")),
        "repos_total": len(push_results),
    }
    (STATE / "swarm_phase2_complete.json").write_text(json.dumps(phase2, indent=2), encoding="utf-8")

    # Re-run swarm gates
    run(["python3", str(SCRIPTS / "swarm_execute_lilith_1_40.py")], timeout=300)
    run(["python3", str(SCRIPTS / "swarm_execute_lilith_41_60.py")], timeout=120)

    print(f"\nPhase 2 sealed: {STATE / 'swarm_phase2_complete.json'}")
    print(f"Repos pushed: {phase2['repos_ok']}/{phase2['repos_total']}")
    return 0 if phase2["repos_ok"] >= phase2["repos_total"] - 1 else 1


if __name__ == "__main__":
    raise SystemExit(main())