# CLAUDE.md — Polsia AI Business Agent (FULLY UNLOCKED)

## Test Commands
```bash
cd backend && python -m pytest tests/unit -v
cd backend && python -m pytest tests/integration -v -m integration
cd frontend && npm test
```

## Architecture
FastAPI (async, Python 3.12) serves the REST API and WebSocket. Celery workers pull tasks from Redis and run agents. Each agent inherits `BasePolsiaAgent` and calls `claude -p "..." --output-format json` as a subprocess. Results are written to PostgreSQL (SQLAlchemy async ORM, 17 tables) and semantic insights are dual-written to ChromaDB. Redis pub/sub broadcasts activity events to the WebSocket, which the Next.js dashboard consumes in real-time.

## Critical Env
- `CLAUDE_CLI_MOCK=true` — makes all agents return stub responses (used in tests/CI)
- `SANDBOX_MODE=false` — FULLY UNLOCKED, all agents use real integrations
- `API_KEY=polsia-unlocked-key` — default auth key

## Adding a New Agent
1. Create `app/agents/<name>/agent.py` with a class inheriting `BasePolsiaAgent`
2. Add to `AGENT_MAP` in `app/agents/crew_factory.py`
3. Add to `VALID_AGENT_TYPES` in `app/services/task_service.py`
4. Add to `AGENT_LABELS` in frontend `src/app/agents/page.tsx`

## Common Pitfalls
- Celery tasks use `asyncio.run()` internally — never share event loops across tasks
- Finance agent creates its own DB session for snapshot — avoid circular deps
- Frontend API client uses `X-API-Key` header — must match backend `settings.api_key`
