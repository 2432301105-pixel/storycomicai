"""FastAPI application entrypoint."""

from __future__ import annotations

import logging
import uuid
from collections.abc import Callable

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse, Response
from starlette.middleware.base import BaseHTTPMiddleware

from api.app.api.responses import error_response
from api.app.api.router import api_router
from api.app.core.config import settings
from api.app.core.logging import configure_logging
from api.app.services.exceptions import DomainError

configure_logging(debug=settings.debug)
logger = logging.getLogger(__name__)


class RequestIDMiddleware(BaseHTTPMiddleware):
    """Inject a request id into request state and response header."""

    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Response],
    ) -> Response:
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response


app = FastAPI(
    title=settings.app_name,
    debug=settings.debug,
)
app.add_middleware(RequestIDMiddleware)
app.include_router(api_router, prefix=settings.api_prefix)


@app.exception_handler(DomainError)
async def domain_error_handler(request: Request, exc: DomainError) -> JSONResponse:
    return error_response(
        request=request,
        code=exc.code,
        message=exc.message,
        status_code=exc.status_code,
    )


@app.exception_handler(RequestValidationError)
async def request_validation_error_handler(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    return error_response(
        request=request,
        code="VALIDATION_ERROR",
        message=str(exc),
        status_code=422,
    )


@app.get("/")
def root() -> dict[str, str]:
    return {"service": "storycomicai-api", "status": "ok"}


@app.on_event("startup")
async def on_startup() -> None:
    logger.info("Starting StoryComicAI API", extra={"env": settings.env})

