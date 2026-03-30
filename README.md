# StoryComicAI

StoryComicAI is an independent monorepo for an iOS-first, AI-assisted personalized comic generation product.
This repository includes backend API, async workers, shared schemas, infrastructure templates, and iOS app scaffolding.

## Repository Structure

```text
storycomicai/
  ios-app/            # SwiftUI app scaffold
  api/                # FastAPI backend (SQLAlchemy + Alembic)
  workers/            # Celery worker processes
  shared-schemas/     # JSON Schemas shared across services
  docs/               # Product and engineering documentation
  infra/              # Local infrastructure and deployment assets
```

## Local Setup

### 1) Prerequisites
- Python 3.11+
- Docker + Docker Compose

### 2) Environment

```bash
cp .env.example .env
```

### 3) Install Dependencies

```bash
make setup
```

### 4) Start Local Infrastructure

```bash
docker compose -f infra/docker/docker-compose.yml up -d
```

### 5) Run Migrations

```bash
make migrate
```

### 6) Run API

```bash
make api-dev
```

### 7) Run Worker

```bash
make worker-dev
```

## Environment Variables

Configuration is read from environment variables prefixed with `SC_`.
See `.env.example` for all required values.

Key values:
- `SC_DATABASE_URL`: PostgreSQL connection string
- `SC_REDIS_URL`: Redis URL
- `SC_CELERY_BROKER_URL`, `SC_CELERY_RESULT_BACKEND`: Celery transport
- `SC_AUTH_JWT_SECRET`: JWT signing secret
- `SC_APPLE_CLIENT_ID`: Apple Sign-In audience
- `SC_STORAGE_PROVIDER`: `mock` or future providers

## Common Commands

```bash
make setup            # create venv and install deps
make api-dev          # run FastAPI in reload mode
make worker-dev       # run Celery worker
make migrate          # apply Alembic migrations
make makemigrations m="add table"  # create migration
make lint             # ruff + mypy
make format           # format and auto-fix lint
make test             # run tests
make clean-ios-artifacts  # remove local iOS build artifacts to free disk
```

## Migration Workflow

1. Update SQLAlchemy models.
2. Generate migration:
   ```bash
   make makemigrations m="describe change"
   ```
3. Review migration file.
4. Apply migration:
   ```bash
   make migrate
   ```

## API and Worker Entrypoints

- API app: `api.app.main:app`
- Celery app: `workers.app.celery_app:celery_app`

## Current MVP Scope in Codebase

- Health endpoints
- Apple Sign-In verification skeleton
- Project create/list
- Photo upload presign + completion flow (storage abstraction)
- Hero preview job enqueue + status
- Job table and worker skeleton

For architecture details, see:
- `docs/engineering/mvp-technical-plan.md`
- `docs/api/openapi.yaml`

## GitHub + Render Workflow (Remote-First)

StoryComicAI can run remote on Render with two profiles:
- free/dev (API + Redis + PostgreSQL, inline jobs)
- paid/full (API + worker + Redis + PostgreSQL)

### 1) Push this repo to GitHub
- Create a dedicated GitHub repository for StoryComicAI.
- Push this monorepo as-is.

### 2) Create Render Blueprint
- In Render, use **Blueprint** and point to this repository.
- Render will read [`render.yaml`](render.yaml) and provision:
  - `storycomicai-api` (web service, free plan)
  - `storycomicai-redis`
  - `storycomicai-postgres`
- Default `render.yaml` is a **free/dev profile**:
  - no dedicated worker service
  - `SC_JOB_QUEUE_MODE=inline` so hero-preview jobs complete without Celery worker
- Full paid profile is preserved in [`render.paid.yaml`](render.paid.yaml) for API + worker deployments.

### 3) Configure required secrets in Render
- `SC_APPLE_CLIENT_ID`
- `SC_AUTH_JWT_SECRET` (auto-generated for API in Blueprint)

### 4) Configure GitHub deploy hooks
- Add these GitHub repository secrets:
  - `RENDER_API_DEPLOY_HOOK_URL`
  - `RENDER_WORKER_DEPLOY_HOOK_URL` (optional for free/dev; required for paid worker deployments)
- Workflow file: `.github/workflows/deploy-render.yml`
- On push to `main`, GitHub always triggers API deploy hook. Worker hook is skipped if secret is not set.

### Render Start Commands
- API start script: `infra/render/start_api.sh`
  - runs Alembic migrations on boot (`SC_RUN_MIGRATIONS_ON_START=true`)
  - starts `uvicorn api.app.main:app`
- Worker start script: `infra/render/start_worker.sh`
  - starts Celery worker for `hero_preview,default` queues
