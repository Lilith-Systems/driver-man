# Polsia Acceptance Testing

## How to Run All Tests

```bash
make test          # Backend unit tests
make test-e2e      # Playwright E2E
make lint          # ruff + ESLint
```

## Test Coverage Map

### Backend Unit (40+ tests, 14 files)
- `test_base_agent.py` — mock call_claude, json parsing, timed_run
- `test_task_service.py` — CRUD operations
- `test_company_service.py` — context building
- `test_activity_service.py` — logging + Redis pub
- `test_memory_service.py` — ChromaDB dual-write
- `test_report_service.py` — daily report lifecycle
- `api/test_agents.py` — trigger, status, validation
- `api/test_config.py` — GET/PUT config, auth
- `api/test_dashboard.py` — summary, activity, health
- `api/test_finance.py` — summary, revenue, expenses
- `api/test_memory.py` — create, search, list
- `api/test_social.py` — posts listing
- `api/test_tasks.py` — create, get, list, 404
- `celery/test_agent_tasks.py` — crew_factory dispatch

### Frontend Unit (30+ tests, 6 files)
- ActivityFeed, AgentStatusGrid, MetricsCard, Sidebar
- useActivityFeed, useAgentStatus hooks

### Integration (testcontainers)
- Real Postgres + Redis round-trip

## Coverage Targets
- Services: 85%
- Agents: 75%
- API: 80%
- Frontend components: 70%
