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
