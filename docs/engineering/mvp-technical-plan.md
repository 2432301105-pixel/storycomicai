# StoryComicAI MVP Technical Plan

## Scope
This document defines the first production-minded MVP slice for StoryComicAI.
The goal is a stable base that supports future modules (story planner, quality scoring, billing, export) without refactoring core architecture.

## MVP Features in This Phase
- FastAPI backend skeleton
- Apple Sign-In verification skeleton endpoint
- Project create/list endpoints
- Photo upload flow with object storage abstraction
- Hero preview job enqueue/status APIs
- PostgreSQL schema foundation
- Celery + Redis worker skeleton
- Shared JSON Schemas for domain contracts

## Non-Goals (Current Phase)
- Real AI image generation
- Billing integration
- Full comic viewer backend resources
- Production object storage vendor integration

## Module Overview

### API (`api/`)
- HTTP request validation
- auth boundary
- orchestration for project/upload/job flows
- response envelope and error conventions

### Worker (`workers/`)
- asynchronous hero preview job execution
- status transitions (`queued -> running -> succeeded/failed`)

### Shared Schemas (`shared-schemas/`)
- domain JSON schemas used across services

### Infra (`infra/`)
- local PostgreSQL and Redis setup

## Request Flow

### Project Creation
1. Authenticated user calls `POST /v1/projects`.
2. API validates payload and creates project in DB.
3. API returns project summary.

### Project Listing
1. Authenticated user calls `GET /v1/projects`.
2. API returns user-scoped project list.

### Photo Upload
1. `POST /v1/projects/{project_id}/photos/presign` returns upload URL.
2. Client uploads directly to storage.
3. `POST /v1/projects/{project_id}/photos/complete` finalizes metadata and validation status.

### Hero Preview
1. `POST /v1/projects/{project_id}/hero-preview` creates generation job and enqueues worker task.
2. Worker updates job status in DB.
3. Client polls `GET /v1/projects/{project_id}/hero-preview/{job_id}`.

## Generation Job Flow
- `queued`: job persisted and queued
- `running`: worker claimed and started
- `succeeded`: result payload persisted
- `failed`: error metadata persisted

## Hero Preview Flow
- Input: project id, selected photo ids, style
- Output (current placeholder): deterministic mock preview asset metadata
- Future: AI render service integration and character consistency scoring

## Architecture Decisions

### Why FastAPI + SQLAlchemy + Alembic
- strong typing with Pydantic and Python type hints
- clean separation of API schema, service logic, and persistence
- reliable migration lifecycle for iterative product development

### Why Celery + Redis
- battle-tested async pipeline pattern
- easy extension for multi-stage generation jobs

### Why Storage Abstraction
- prevents vendor lock-in
- enables local mock provider for deterministic development/testing

### Why Monorepo
- shared contracts and synchronized evolution
- simple CI and consistent standards across API/worker/schemas

## Future Extension Points
- Story planner service (scene/page/panel graph)
- Quality gate pipeline
- Billing entitlements
- Export jobs
- Observability (metrics/tracing dashboards)
