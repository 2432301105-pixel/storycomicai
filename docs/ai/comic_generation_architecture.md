# StoryComicAI Comic Generation Architecture

## Goal
StoryComicAI does not need a generic image classifier. It needs a story-to-comic pipeline that turns a user's story and character photos into a consistent, premium comic package.

## Product Pipeline
1. User story input
2. Story planner
3. Character bible
4. Style guide
5. Reference retrieval
6. Panel prompt building
7. Panel rendering
8. Page composition
9. Quality pass
10. Comic package delivery for reveal / preview / reader / export

## Core Services
- `story_planner.py`
  - Breaks story text into beats and scene intents.
- `character_bible_service.py`
  - Builds a persistent character identity profile from uploaded photos and story cues.
- `style_guide_service.py`
  - Converts style preset into rendering, framing, bubble, and page-layout rules.
- `reference_index_service.py`
  - Retrieves comic reference assets by taxonomy tags.
- `panel_prompt_service.py`
  - Produces continuity-aware prompts for each panel.
- `panel_generation_service.py`
  - Converts panel specs into render-ready placeholders or future model requests.
  - Talks only to the provider contract, never directly to a model vendor.
- `render_provider.py`
  - Normalizes external render services behind one backend contract.
  - Supports direct panel responses and async job-based providers.
- `page_composer_service.py`
  - Groups panels into comic pages with narrative purpose.
- `comic_generation_orchestrator.py`
  - Coordinates the full blueprint used by backend and iOS.

## Taxonomy Axes
The reference library is not classified like CIFAR-10. It is indexed by comic-specific axes:
- `style`
- `shot_type`
- `scene_type`
- `lighting`
- `mood`
- `environment`
- `character_pose`
- `panel_density`
- `panel_role`
- `render_traits`
- `speech_density`

## Reference Sourcing Rule
- Pinterest may be used only as a manual inspiration / moodboard source.
- Pinterest content must not be scraped, downloaded into datasets, used as retrieval assets, or used for model training.
- Production reference assets must come from licensed, public-domain, first-party, or explicitly permitted sources.

## Why This Is The Right Shape
- We should not train a foundation image model from scratch for the MVP.
- We should own the orchestration layer: planning, taxonomy, reference retrieval, continuity, composition.
- A future image stack can be swapped in under `panel_generation_service.py` without changing the product contract.

## Backend Contracts
Near-term backend-driven UI should rely on:
- `GET /v1/projects/{project_id}/comic-package`
  - returns generated pages plus `generationBlueprint`
- `GET /v1/projects/{project_id}/generation-blueprint`
  - returns blueprint alone for generation-progress UI

## Render Provider Adapter Contract
The render layer is provider-driven, not model-driven.

Required environment variables:
- `SC_AI_RENDER_PROVIDER=mock|remote_http`
- `SC_AI_RENDER_PROVIDER_BASE_URL`

Optional environment variables:
- `SC_AI_RENDER_PROVIDER_API_KEY`
- `SC_AI_RENDER_PROVIDER_MODEL_ID`
- `SC_AI_RENDER_PROVIDER_ADAPTER_ID`
- `SC_AI_RENDER_PROVIDER_SUBMIT_PATH`
- `SC_AI_RENDER_PROVIDER_STATUS_PATH_TEMPLATE`
- `SC_AI_RENDER_PROVIDER_POLL_INTERVAL_MS`
- `SC_AI_RENDER_PROVIDER_MAX_POLL_SECONDS`
- `SC_AI_RENDER_PROVIDER_AUTH_HEADER`
- `SC_AI_RENDER_PROVIDER_AUTH_SCHEME`

Activation rule:
- If `SC_AI_RENDER_PROVIDER_BASE_URL` is present, StoryComicAI will promote the provider to `remote_http` even when `SC_AI_RENDER_PROVIDER` is left as `mock`.
- This keeps local development simple while allowing production/staging to activate the real vendor with environment-only changes.

Expected provider behaviors:
1. Direct mode
   - `POST {submit_path}` returns `{ panels: [...] }`
2. Async mode
   - `POST {submit_path}` returns `{ jobId, status }`
   - backend polls `{status_path_template}` until `{ panels: [...] }` is available

This keeps StoryComicAI free to swap providers without changing:
- story planning
- character bible synthesis
- style guide generation
- iOS generation progress UI

## iOS Expectations
iOS should treat generation as a structured pipeline, not a spinner:
- show beats/scenes during generation
- use `generationBlueprint` to explain what is being built
- reveal final comic using backend-produced cover/pages

## Implementation Strategy
### MVP
- deterministic story planning
- deterministic character bible synthesis
- deterministic reference retrieval
- placeholder panel render assets
- backend-driven blueprint returned to iOS

### V2
- photo-conditioned character identity extraction
- style adapters / LoRA routing
- actual image generation with continuity guidance
- page-level quality reranking and repair passes

## Storage for Final Assets
Final panel/page/cover assets must be persisted after composition.

Required storage environment:
- `SC_STORAGE_PROVIDER=mock|s3`
- `SC_STORAGE_BUCKET`

Optional S3-compatible environment:
- `SC_STORAGE_REGION`
- `SC_STORAGE_ENDPOINT_URL`
- `SC_STORAGE_ACCESS_KEY_ID`
- `SC_STORAGE_SECRET_ACCESS_KEY`
- `SC_STORAGE_SESSION_TOKEN`
- `SC_STORAGE_PUBLIC_BASE_URL`

Behavior:
- `mock` writes composed assets to local disk for development.
- `s3` uploads composed assets to object storage and the rendered-asset routes redirect to presigned download URLs.
