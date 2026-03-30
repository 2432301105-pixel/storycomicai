"""Test fixtures."""

from __future__ import annotations

import uuid
from collections.abc import Generator
from unittest.mock import MagicMock

import pytest
from fastapi.testclient import TestClient

from api.app.api.dependencies import get_current_user
from api.app.db.session import get_db_session
from api.app.main import app
from api.app.models.user import User


@pytest.fixture
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture
def fake_db() -> MagicMock:
    return MagicMock()


@pytest.fixture
def current_user() -> User:
    return User(id=uuid.uuid4(), apple_sub="test-apple-sub", email="test@example.com")


@pytest.fixture
def authenticated_client(fake_db: MagicMock, current_user: User) -> Generator[TestClient, None, None]:
    def override_db() -> Generator[MagicMock, None, None]:
        yield fake_db

    def override_user() -> User:
        return current_user

    app.dependency_overrides[get_db_session] = override_db
    app.dependency_overrides[get_current_user] = override_user
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.clear()
