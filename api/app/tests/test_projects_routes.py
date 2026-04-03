"""Project route tests."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from unittest.mock import patch

from fastapi.testclient import TestClient

from api.app.schemas.project import ProjectData


def test_create_project_accepts_story_text(authenticated_client: TestClient) -> None:
    project_id = uuid.uuid4()
    with patch(
        "api.app.api.routes.projects.project_service.create_project",
        return_value=ProjectData(
            id=project_id,
            title="Shadow Protocol",
            story_text="A courier discovers the city has been staging its own cover-up for years.",
            style="cinematic",
            target_pages=12,
            free_preview_pages=3,
            status="draft",
            is_unlocked=False,
            created_at_utc=datetime.now(UTC),
            updated_at_utc=datetime.now(UTC),
        ),
    ) as mocked_create:
        response = authenticated_client.post(
            "/v1/projects",
            json={
                "title": "Shadow Protocol",
                "story_text": "A courier discovers the city has been staging its own cover-up for years.",
                "style": "cinematic",
                "target_pages": 12,
            },
        )

    assert response.status_code == 201
    payload = response.json()
    assert payload["error"] is None
    assert payload["data"]["story_text"] == "A courier discovers the city has been staging its own cover-up for years."
    mocked_create.assert_called_once()
