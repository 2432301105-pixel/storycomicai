#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH=.

SC_WORKER_QUEUES="${SC_WORKER_QUEUES:-hero_preview,default}"
SC_WORKER_LOG_LEVEL="${SC_WORKER_LOG_LEVEL:-INFO}"
SC_WORKER_CONCURRENCY="${SC_WORKER_CONCURRENCY:-2}"

echo "[render][worker] starting celery queues=${SC_WORKER_QUEUES} concurrency=${SC_WORKER_CONCURRENCY}"
exec celery -A workers.app.celery_app:celery_app worker \
  -Q "${SC_WORKER_QUEUES}" \
  --loglevel="${SC_WORKER_LOG_LEVEL}" \
  --concurrency="${SC_WORKER_CONCURRENCY}"
