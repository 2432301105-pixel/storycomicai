"""Configuration management."""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field, field_validator
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
    storage_presign_ttl_seconds: int = 900
    export_artifact_dir: str = "/tmp/storycomicai-artifacts"
    export_download_token_ttl_seconds: int = 3600
    ai_render_provider: Literal["mock", "remote"] = "mock"

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


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Cached settings factory."""

    return Settings()


settings = get_settings()
