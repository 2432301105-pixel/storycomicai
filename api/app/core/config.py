"""Configuration management."""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import AliasChoices, Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_prefix="SC_",
        env_file=(".env", "../.env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "StoryComicAI API"
    env: Literal["local", "staging", "production"] = "local"
    debug: bool = False
    api_prefix: str = "/v1"

    database_url: str = "sqlite+pysqlite:////tmp/storycomicai.db"

    redis_url: str = "redis://localhost:6379/0"
    celery_broker_url: str = "redis://localhost:6379/0"
    celery_result_backend: str = "redis://localhost:6379/1"
    job_queue_mode: Literal["celery", "inline"] = "celery"

    auth_jwt_secret: str = Field(default="change-me", min_length=8)
    auth_jwt_algorithm: str = "HS256"
    auth_access_token_expire_minutes: int = 120

    apple_client_id: str = "com.storycomicai.app"
    apple_issuer: str = "https://appleid.apple.com"
    allow_unverified_apple_token_in_local: bool = True

    storage_provider: Literal["mock", "s3"] = "mock"
    storage_bucket: str = "storycomicai-local"
    storage_region: str | None = Field(
        default=None,
        validation_alias=AliasChoices(
            "SC_STORAGE_REGION",
            "SC_AWS_REGION",
            "AWS_REGION",
            "AWS_DEFAULT_REGION",
        ),
    )
    storage_endpoint_url: str | None = Field(
        default=None,
        validation_alias=AliasChoices(
            "SC_STORAGE_ENDPOINT_URL",
            "SC_S3_ENDPOINT_URL",
            "AWS_ENDPOINT_URL_S3",
        ),
    )
    storage_access_key_id: str | None = Field(
        default=None,
        validation_alias=AliasChoices(
            "SC_STORAGE_ACCESS_KEY_ID",
            "SC_AWS_ACCESS_KEY_ID",
            "AWS_ACCESS_KEY_ID",
        ),
    )
    storage_secret_access_key: str | None = Field(
        default=None,
        validation_alias=AliasChoices(
            "SC_STORAGE_SECRET_ACCESS_KEY",
            "SC_AWS_SECRET_ACCESS_KEY",
            "AWS_SECRET_ACCESS_KEY",
        ),
    )
    storage_session_token: str | None = Field(
        default=None,
        validation_alias=AliasChoices(
            "SC_STORAGE_SESSION_TOKEN",
            "SC_AWS_SESSION_TOKEN",
            "AWS_SESSION_TOKEN",
        ),
    )
    storage_public_base_url: str | None = Field(default=None, validation_alias=AliasChoices("SC_STORAGE_PUBLIC_BASE_URL"))
    storage_presign_ttl_seconds: int = 900
    export_artifact_dir: str = "/tmp/storycomicai-artifacts"
    export_download_token_ttl_seconds: int = 3600
    anthropic_api_key: str | None = None
    openai_api_key: str | None = None

    ai_render_provider: Literal["mock", "remote", "remote_http", "dalle"] = "mock"
    ai_render_provider_base_url: str | None = None
    ai_render_provider_api_key: str | None = None
    ai_render_provider_timeout_seconds: int = 45
    ai_render_provider_model_id: str = "storycomicai-panel-v1"
    ai_render_provider_adapter_id: str | None = None
    ai_render_provider_submit_path: str = "/render/panels"
    ai_render_provider_status_path_template: str = "/render/jobs/{job_id}"
    ai_render_provider_poll_interval_ms: int = 1000
    ai_render_provider_max_poll_seconds: int = 90
    ai_render_provider_auth_header: str = "Authorization"
    ai_render_provider_auth_scheme: str = "Bearer"

    @field_validator("database_url", mode="before")
    @classmethod
    def normalize_database_url(cls, value: object) -> object:
        """Normalize Render-style postgres URLs to SQLAlchemy psycopg URLs."""

        if not isinstance(value, str):
            return value

        normalized = value.strip()
        if normalized.startswith("postgres://"):
            return normalized.replace("postgres://", "postgresql+psycopg://", 1)
        if normalized.startswith("postgresql://"):
            return normalized.replace("postgresql://", "postgresql+psycopg://", 1)
        return normalized

    @field_validator("ai_render_provider", mode="before")
    @classmethod
    def normalize_render_provider(cls, value: object) -> object:
        if not isinstance(value, str):
            return value
        normalized = value.strip().lower()
        if normalized == "remote":
            return "remote_http"
        if normalized in {"dall-e", "dall_e", "dall-e-3", "dallee"}:
            return "dalle"
        return normalized


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Cached settings factory."""

    return Settings()


settings = get_settings()
