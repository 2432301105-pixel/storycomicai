"""Object storage abstraction."""

from __future__ import annotations

import secrets
from dataclasses import dataclass
from typing import Protocol

from api.app.core.config import settings


@dataclass(frozen=True)
class StoredAssetReference:
    """Stable asset reference returned by the storage abstraction."""

    storage_key: str
    source_url: str
    resolved_url: str
    persisted: bool


class ObjectStorageClient(Protocol):
    """Storage provider contract for upload URLs and persisted asset references."""

    def create_presigned_upload_url(
        self,
        *,
        storage_key: str,
        mime_type: str,
        expires_in_seconds: int,
    ) -> str: ...

    def persist_external_asset_reference(
        self,
        *,
        storage_key: str,
        source_url: str,
        expires_in_seconds: int,
    ) -> StoredAssetReference: ...


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

    def persist_external_asset_reference(
        self,
        *,
        storage_key: str,
        source_url: str,
        expires_in_seconds: int,
    ) -> StoredAssetReference:
        del expires_in_seconds
        resolved_url = source_url.strip() if source_url.strip() else f"{self.base_url}/assets/{storage_key}"
        return StoredAssetReference(
            storage_key=storage_key,
            source_url=source_url,
            resolved_url=resolved_url,
            persisted=False,
        )


def get_object_storage_client() -> ObjectStorageClient:
    """Factory for configured storage implementation."""

    if settings.storage_provider == "mock":
        return MockObjectStorageClient()

    # TODO: Add S3 provider implementation when moving beyond local environment.
    return MockObjectStorageClient()
