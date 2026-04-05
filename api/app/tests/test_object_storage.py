"""Object storage adapter tests."""

from __future__ import annotations

import uuid
from unittest.mock import patch

from api.app.core.config import settings
from api.app.services.object_storage import S3ObjectStorageClient


class _FakeS3Client:
    def __init__(self) -> None:
        self.put_calls: list[dict[str, object]] = []
        self.presign_calls: list[dict[str, object]] = []

    def put_object(self, **kwargs):
        self.put_calls.append(kwargs)
        return {"ETag": "fake"}

    def generate_presigned_url(self, operation_name: str, Params: dict[str, object], ExpiresIn: int) -> str:
        self.presign_calls.append(
            {
                "operation_name": operation_name,
                "params": Params,
                "expires": ExpiresIn,
            }
        )
        key = Params["Key"]
        return f"https://bucket.example.com/{key}?op={operation_name}&expires={ExpiresIn}"


def test_s3_object_storage_client_persists_bytes_and_returns_download_url() -> None:
    fake = _FakeS3Client()
    storage = S3ObjectStorageClient(
        bucket="storycomicai-prod",
        endpoint_url="https://s3.example.com",
        region_name="eu-central-1",
        access_key_id="key",
        secret_access_key="secret",
        session_token=None,
        client_factory=lambda: fake,
    )

    asset = storage.persist_bytes(
        storage_key="projects/demo/pages/page-01-full",
        data=b"png-bytes",
        content_type="image/png",
        expires_in_seconds=900,
    )

    assert asset.persisted is True
    assert asset.storage_key == "projects/demo/pages/page-01-full"
    assert asset.resolved_url.startswith("https://bucket.example.com/projects/demo/pages/page-01-full")
    assert fake.put_calls[0]["Bucket"] == "storycomicai-prod"
    assert fake.put_calls[0]["ContentType"] == "image/png"
    assert fake.presign_calls[-1]["operation_name"] == "get_object"


def test_rendered_asset_route_redirects_to_presigned_storage_url(client) -> None:
    project_id = uuid.uuid4()

    class _RedirectingStorage:
        def create_presigned_download_url(self, *, storage_key: str, expires_in_seconds: int) -> str:
            assert storage_key == f"projects/{project_id}/pages/page-01-full"
            assert expires_in_seconds == settings.storage_presign_ttl_seconds
            return "https://bucket.example.com/projects/demo/pages/page-01-full?sig=abc"

    original_provider = settings.storage_provider
    settings.storage_provider = "s3"
    try:
        with patch("api.app.api.routes.projects.resolve_mock_storage_path", return_value=None), patch(
            "api.app.api.routes.projects.get_object_storage_client",
            return_value=_RedirectingStorage(),
        ):
            response = client.get(f"/v1/projects/{project_id}/rendered-assets/page/1?variant=full", follow_redirects=False)
    finally:
        settings.storage_provider = original_provider

    assert response.status_code == 307
    assert response.headers["location"] == "https://bucket.example.com/projects/demo/pages/page-01-full?sig=abc"
