#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH=.

if [[ "${SC_RUN_MIGRATIONS_ON_START:-true}" == "true" ]]; then
  echo "[render][api] applying alembic migrations"
  alembic -c api/alembic.ini upgrade head
fi

echo "[render][api] starting uvicorn on port ${PORT:-8000}"
exec uvicorn api.app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
