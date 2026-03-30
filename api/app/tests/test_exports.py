"""Export endpoint and artifact tests."""

from __future__ import annotations

import io
import uuid
import zipfile
from unittest.mock import patch

from fastapi.testclient import TestClient

from api.app.models.export_job import ExportStatus, ExportType
from api.app.schemas.export import ExportCreateData, ExportStatusData
from api.app.services.export_service import ExportService


def test_create_export_success(authenticated_client: TestClient) -> None:
    project_id = uuid.uuid4()
    job_id = uuid.uuid4()
    with patch(
        "api.app.api.routes.projects.export_service.create_export",
        return_value=ExportCreateData(
            jobId=job_id,
            projectId=project_id,
            type=ExportType.PDF,
            status=ExportStatus.SUCCEEDED,
        ),
    ):
        response = authenticated_client.post(
            f"/v1/projects/{project_id}/exports",
            json={"type": "pdf", "preset": "screen", "includeCover": True},
        )

    assert response.status_code == 202
    payload = response.json()
    assert payload["error"] is None
    assert payload["data"]["jobId"] == str(job_id)
    assert payload["data"]["type"] == "pdf"


def test_export_status_success(authenticated_client: TestClient) -> None:
    project_id = uuid.uuid4()
    job_id = uuid.uuid4()
    with patch(
        "api.app.api.routes.projects.export_service.get_export_status",
        return_value=ExportStatusData(
            jobId=job_id,
            projectId=project_id,
            type=ExportType.PDF,
            status=ExportStatus.SUCCEEDED,
            progressPct=100,
            artifactUrl=f"https://example.com/exports/{job_id}.pdf",
            errorCode=None,
            errorMessage=None,
            retryable=False,
        ),
    ):
        response = authenticated_client.get(f"/v1/projects/{project_id}/exports/{job_id}")

    assert response.status_code == 200
    payload = response.json()
    assert payload["data"]["status"] == "succeeded"
    assert payload["data"]["artifactUrl"].endswith(".pdf")


def test_export_service_builds_pdf_bytes() -> None:
    service = ExportService()
    project = type("ProjectStub", (), {"title": "Shadow Run", "style": "cinematic", "target_pages": 8, "free_preview_pages": 3})()

    artifact = service._build_pdf(project=project)

    assert artifact[:4] == b"%PDF"
    assert len(artifact) > 128


def test_export_service_builds_image_bundle_zip() -> None:
    service = ExportService()
    project = type("ProjectStub", (), {"title": "Shadow Run", "style": "cinematic", "target_pages": 8, "free_preview_pages": 3})()

    artifact = service._build_image_bundle(project=project, include_cover=True)

    with zipfile.ZipFile(io.BytesIO(artifact), "r") as archive:
        names = archive.namelist()

    assert "manifest.txt" in names
    assert "cover.svg" in names
    assert any(name.startswith("pages/page-") for name in names)
