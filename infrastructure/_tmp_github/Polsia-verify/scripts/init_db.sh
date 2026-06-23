#!/bin/bash
set -e

echo "Running database migrations..."
cd /app/backend && alembic upgrade head

echo "Seeding company data..."
cd /app/backend && python scripts/seed_company.py

echo "Database initialized successfully."
