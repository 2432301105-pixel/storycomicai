"""Object storage abstraction."""

from __future__ import annotations

import secrets
from dataclasses import dataclass
from typing import Protocol

from api.app.core.config import settings


class ObjectStorageClient(Protocol):
    """Storage provider contract for upload URLs."""

    def create_presigned_upload_url(
        self,
        *,
        storage_key: str,
        mime_type: str,
        expires_in_seconds: int,
    ) -> str: ...


@dataclass
class MockObjectStorageClient:
    """Mock storage provider for local development."""

    base_url: str = "https://mock-storage.storycomicai.local"

    def create_presigned_upload_url(
        self,
        *,
        storage_key: str,
        mime_type: str,
        expires_in_seconds: int,
    ) -> str:
        token = secrets.token_urlsafe(16)
        return (
            f"{self.base_url}/upload/{storage_key}"
            f"?token={token}&mime_type={mime_type}&expires_in={expires_in_seconds}"
        )


def get_object_storage_client() -> ObjectStorageClient:
    """Factory for configured storage implementation."""

    if settings.storage_provider == "mock":
        return MockObjectStorageClient()

    # TODO: Add S3 provider implementation when moving beyond local environment.
    return MockObjectStorageClient()

