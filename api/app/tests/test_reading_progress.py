"""Reading progress tests."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from api.app.models.project import Project
from api.app.schemas.reading_progress import ReadingProgressData, ReadingProgressUpdateRequest
from api.app.services.exceptions import DomainError
from api.app.services.reading_progress_service import ReadingProgressService


def _project(project_id: uuid.UUID) -> Project:
    project = Project(
        id=project_id,
        user_id=uuid.uuid4(),
        title="Shadow Run",
        style="cinematic",
        target_pages=8,
        free_preview_pages=3,
        is_unlocked=False,
    )
    project.reading_page_index = 0
    project.reading_last_opened_at = None
    return project


def test_update_reading_progress_success(authenticated_client: TestClient) -> None:
    project_id = uuid.uuid4()
    with patch(
        "api.app.api.routes.projects.reading_progress_service.update_progress",
        return_value=ReadingProgressData(
            projectId=project_id,
            currentPageIndex=2,
            lastOpenedAtUtc=datetime.now(UTC),
        ),
    ):
        response = authenticated_client.patch(
            f"/v1/projects/{project_id}/reading-progress",
            json={
                "currentPageIndex": 2,
                "lastOpenedAtUtc": datetime.now(UTC).isoformat(),
            },
        )

    assert response.status_code == 200
    payload = response.json()
    assert payload["error"] is None
    assert payload["data"]["currentPageIndex"] == 2


def test_update_reading_progress_invalid_index_maps_domain_error(authenticated_client: TestClient) -> None:
    project_id = uuid.uuid4()
    with patch(
        "api.app.api.routes.projects.reading_progress_service.update_progress",
        side_effect=DomainError(
            code="INVALID_READING_PROGRESS",
            message="currentPageIndex must be less than 8.",
            status_code=422,
        ),
    ):
        response = authenticated_client.patch(
            f"/v1/projects/{project_id}/reading-progress",
            json={
                "currentPageIndex": 99,
                "lastOpenedAtUtc": datetime.now(UTC).isoformat(),
            },
        )

    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "INVALID_READING_PROGRESS"


def test_reading_progress_service_persists_to_project(current_user: object) -> None:
    project_id = uuid.uuid4()
    project = _project(project_id)
    fake_db = MagicMock()
    fake_db.scalar.return_value = project
    service = ReadingProgressService()

    data = service.update_progress(
        db=fake_db,
        user=current_user,
        project_id=project_id,
        payload=ReadingProgressUpdateRequest(
            currentPageIndex=3,
            lastOpenedAtUtc=datetime.now(UTC),
        ),
    )

    assert data.current_page_index == 3
    assert project.reading_page_index == 3
    fake_db.commit.assert_called_once()


def test_reading_progress_service_rejects_out_of_bounds(current_user: object) -> None:
    project_id = uuid.uuid4()
    project = _project(project_id)
    fake_db = MagicMock()
    fake_db.scalar.return_value = project
    service = ReadingProgressService()

    with pytest.raises(DomainError) as exc_info:
        service.update_progress(
            db=fake_db,
            user=current_user,
            project_id=project_id,
            payload=ReadingProgressUpdateRequest(
                currentPageIndex=10,
                lastOpenedAtUtc=datetime.now(UTC),
            ),
        )

    assert exc_info.value.code == "INVALID_READING_PROGRESS"
