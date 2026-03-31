#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH=.

if [[ -z "${SC_DATABASE_URL:-}" ]]; then
  export SC_DATABASE_URL="sqlite+pysqlite:////tmp/storycomicai.db"
  echo "[render][api] SC_DATABASE_URL not set; using SQLite fallback at ${SC_DATABASE_URL}"
fi

if [[ "${SC_RUN_MIGRATIONS_ON_START:-true}" == "true" ]]; then
  if [[ "${SC_DATABASE_URL}" == sqlite* ]]; then
    echo "[render][api] bootstrapping schema with SQLAlchemy create_all for SQLite fallback"
    python -m api.app.db.bootstrap
  else
    echo "[render][api] applying alembic migrations"
    alembic -c api/alembic.ini upgrade head
  fi
fi

echo "[render][api] starting uvicorn on port ${PORT:-8000}"
exec uvicorn api.app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
