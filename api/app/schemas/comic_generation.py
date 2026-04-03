"""Schemas for comic generation job lifecycle."""

from __future__ import annotations

import uuid

from pydantic import BaseModel, ConfigDict, Field

from api.app.schemas.ai.generation import ComicGenerationBlueprintData


class ComicGenerationStartRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    force_regenerate: bool = Field(alias="forceRegenerate", default=False)


class ComicGenerationStartData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    job_id: uuid.UUID = Field(alias="jobId")
    project_id: uuid.UUID = Field(alias="projectId")
    status: str
    current_stage: str = Field(alias="currentStage")
    progress_pct: int = Field(alias="progressPct")
    generation_blueprint: ComicGenerationBlueprintData | None = Field(alias="generationBlueprint", default=None)
    rendered_pages_count: int = Field(alias="renderedPagesCount", default=0)
    rendered_panels_count: int = Field(alias="renderedPanelsCount", default=0)
    provider_name: str | None = Field(alias="providerName", default=None)
    error_message: str | None = Field(alias="errorMessage", default=None)


class ComicGenerationStatusData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    job_id: uuid.UUID = Field(alias="jobId")
    project_id: uuid.UUID = Field(alias="projectId")
    status: str
    current_stage: str = Field(alias="currentStage")
    progress_pct: int = Field(alias="progressPct")
    generation_blueprint: ComicGenerationBlueprintData | None = Field(alias="generationBlueprint", default=None)
    rendered_pages_count: int = Field(alias="renderedPagesCount", default=0)
    rendered_panels_count: int = Field(alias="renderedPanelsCount", default=0)
    provider_name: str | None = Field(alias="providerName", default=None)
    error_message: str | None = Field(alias="errorMessage", default=None)
