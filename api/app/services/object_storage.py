"""Object storage abstraction."""

from __future__ import annotations

import mimetypes
import secrets
from dataclasses import dataclass
from pathlib import Path
from typing import Protocol

import httpx

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

    def persist_bytes(
        self,
        *,
        storage_key: str,
        data: bytes,
        content_type: str,
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
        if source_url.strip():
            downloaded = self._download_bytes(source_url=source_url.strip())
            if downloaded is not None:
                content, content_type = downloaded
                return self.persist_bytes(
                    storage_key=storage_key,
                    data=content,
                    content_type=content_type,
                    expires_in_seconds=0,
                )
        resolved_url = source_url.strip() if source_url.strip() else f"{self.base_url}/assets/{storage_key}"
        return StoredAssetReference(
            storage_key=storage_key,
            source_url=source_url,
            resolved_url=resolved_url,
            persisted=False,
        )

    def persist_bytes(
        self,
        *,
        storage_key: str,
        data: bytes,
        content_type: str,
        expires_in_seconds: int,
    ) -> StoredAssetReference:
        del expires_in_seconds
        destination = mock_storage_path_for_key(storage_key=storage_key, content_type=content_type)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        return StoredAssetReference(
            storage_key=storage_key,
            source_url="",
            resolved_url=f"{self.base_url}/assets/{storage_key}",
            persisted=True,
        )

    @staticmethod
    def _download_bytes(*, source_url: str) -> tuple[bytes, str] | None:
        if not source_url.startswith(("http://", "https://")):
            return None
        try:
            response = httpx.get(source_url, timeout=5.0, follow_redirects=True)
            response.raise_for_status()
        except httpx.HTTPError:
            return None

        content_type = response.headers.get("content-type", "application/octet-stream").split(";")[0].strip().lower()
        if content_type in {"image/svg+xml", "text/html", "application/json"}:
            return None
        if not content_type.startswith("image/"):
            return None
        return response.content, content_type


def mock_storage_root() -> Path:
    return Path(settings.export_artifact_dir).expanduser() / "rendered-storage"


def mock_storage_path_for_key(*, storage_key: str, content_type: str) -> Path:
    extension = mimetypes.guess_extension(content_type) or ".bin"
    safe_key = storage_key.strip("/").replace("..", "_")
    return mock_storage_root() / f"{safe_key}{extension}"


def resolve_mock_storage_path(*, storage_key: str) -> Path | None:
    base = mock_storage_root() / storage_key.strip("/")
    parent = base.parent
    if not parent.exists():
        return None
    matches = sorted(parent.glob(f"{base.name}.*"))
    return matches[0] if matches else None


def get_object_storage_client() -> ObjectStorageClient:
    """Factory for configured storage implementation."""

    if settings.storage_provider == "mock":
        return MockObjectStorageClient()

    # TODO: Add S3 provider implementation when moving beyond local environment.
    return MockObjectStorageClient()
