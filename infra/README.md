# Infrastructure

Local development infrastructure and deployment templates for StoryComicAI.

- `docker/`: local PostgreSQL and Redis stack
- `render/`: Render runtime start scripts for API and worker

## Render Deployment Files

- Blueprint: `/render.yaml`
- API start: `infra/render/start_api.sh`
- Worker start: `infra/render/start_worker.sh`
