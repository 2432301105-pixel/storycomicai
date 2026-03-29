"""API response helpers."""

from __future__ import annotations

from typing import Any

from fastapi import Request
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse

from api.app.schemas.common import ApiResponse, ErrorDetail


def success_response(
    *,
    request: Request,
    data: Any,
    status_code: int = 200,
) -> JSONResponse:
    payload = ApiResponse[Any](request_id=request.state.request_id, data=data, error=None)
    return JSONResponse(status_code=status_code, content=jsonable_encoder(payload))


def error_response(
    *,
    request: Request,
    code: str,
    message: str,
    status_code: int,
) -> JSONResponse:
    payload = ApiResponse[Any](
        request_id=request.state.request_id,
        data=None,
        error=ErrorDetail(code=code, message=message),
    )
    return JSONResponse(status_code=status_code, content=jsonable_encoder(payload))

