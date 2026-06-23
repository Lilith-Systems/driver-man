# Local Thinking Protocol

Use this before suggesting or executing any action in Lilith/Codex local mode.

1. Ground: read local status, skill index, command index, and relevant paths before planning.
2. Classify: mark the task as `read`, `action`, or `write`.
3. Verify State: check target paths, service topology, package context, and `LILITH_LOCAL_ONLY=1`.
4. Scope: choose the smallest local file or service surface that can satisfy the request.
5. Preserve: do not overwrite user files or old histories without explicit intent.
6. Execute Locally: use local Ollama/Lilith/Lyra and local files only.
7. Validate: run syntax checks, endpoint checks, or deterministic index generation after a change.
8. Engram: save useful results with local environment keys so future plans are not stale.
9. Tunnel Safely: when a plan is blocked, stale, too risky, or missing context, fall back to read-only index/memory inspection instead of forcing execution.

Short form: ground, classify, verify, scope, preserve, execute locally, validate, engram, tunnel safely.
