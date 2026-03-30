"""Export job schemas."""

from __future__ import annotations

import uuid

from pydantic import BaseModel, ConfigDict, Field

from api.app.models.export_job import ExportPreset, ExportStatus, ExportType


class ExportCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", populate_by_name=True)

    type: ExportType
    preset: ExportPreset
    include_cover: bool = Field(alias="includeCover", default=True)


class ExportCreateData(BaseModel):
    model_config = ConfigDict(extra="forbid", populate_by_name=True)

    job_id: uuid.UUID = Field(alias="jobId")
    project_id: uuid.UUID = Field(alias="projectId")
    type: ExportType
    status: ExportStatus


class ExportStatusData(BaseModel):
    model_config = ConfigDict(extra="forbid", populate_by_name=True)

    job_id: uuid.UUID = Field(alias="jobId")
    project_id: uuid.UUID = Field(alias="projectId")
    type: ExportType
    status: ExportStatus
    progress_pct: int | None = Field(alias="progressPct", default=None)
    artifact_url: str | None = Field(alias="artifactUrl", default=None)
    error_code: str | None = Field(alias="errorCode", default=None)
    error_message: str | None = Field(alias="errorMessage", default=None)
    retryable: bool = False
