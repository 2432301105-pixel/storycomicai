"""Shared API schema objects."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Generic, TypeVar

from pydantic import BaseModel, ConfigDict

DataT = TypeVar("DataT")


class ErrorDetail(BaseModel):
    code: str
    message: str


class ApiResponse(BaseModel, Generic[DataT]):
    request_id: str
    data: DataT | None = None
    error: ErrorDetail | None = None


class HealthData(BaseModel):
    status: str
    timestamp_utc: datetime


class MessageData(BaseModel):
    message: str


class Pagination(BaseModel):
    model_config = ConfigDict(extra="forbid")

    limit: int = 20
    cursor: str | None = None


class GenericDictData(BaseModel):
    model_config = ConfigDict(extra="allow")

    payload: dict[str, Any]

