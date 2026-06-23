.PHONY: up down build logs shell-backend migrate seed init-db test-unit test test-frontend test-e2e lint lint-backend lint-frontend reset-db

up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build

logs:
	docker compose logs -f

shell-backend:
	docker compose exec backend bash

migrate:
	docker compose exec backend alembic upgrade head

seed:
	docker compose exec backend python scripts/seed_company.py

init-db: migrate seed

test-unit:
	cd backend && python -m pytest tests/unit -v

test: test-unit

test-integration:
	cd backend && python -m pytest tests/integration -v -m integration

test-frontend:
	cd frontend && npm test

test-e2e:
	cd e2e && npx playwright test

lint-backend:
	cd backend && ruff check app/ tests/

lint-frontend:
	cd frontend && npm run lint

lint: lint-backend lint-frontend

reset-db:
	docker compose down -v
	docker compose up -d postgres redis
	sleep 3
	make init-db
