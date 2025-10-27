import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError, StarletteHTTPException
from fastapi.responses import JSONResponse

from ssrq_editio.entrypoints.app.shared.dependencies import get_lang
from ssrq_editio.entrypoints.app.views.models.error import ErrorViewModel

API_PREFIX = "/api"
ssrq_server_log = logging.getLogger("uvicorn.error")


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException):
        """Handle Starlette/FastAPI HTTPException; log 4xx as WARNING and 5xx as ERROR; return JSON for API paths, HTML otherwise."""
        lang = await get_lang(
            x_lang=request.headers.get("x-lang"), lang=request.query_params.get("lang")
        )
        level = logging.ERROR if exc.status_code >= 500 else logging.WARNING
        ssrq_server_log.log(
            level,
            "HTTP Error",
            extra={
                "path": request.url.path,
                "method": request.method,
                "status_code": exc.status_code,
                "lang": lang,
            },
            exc_info=(type(exc), exc, exc.__traceback__),
        )
        if request.url.path.startswith(API_PREFIX):
            return JSONResponse(
                {"detail": exc.detail},
                status_code=exc.status_code,
                headers=getattr(exc, "headers", None) or {},
            )
        else:
            return await ErrorViewModel(
                request=request,
                lang=lang,
                status_code=exc.status_code,
            ).to_html()

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        """Handle validation errors (422); log WARNING; return JSON for API paths, HTML otherwise."""
        lang = await get_lang(
            x_lang=request.headers.get("x-lang"), lang=request.query_params.get("lang")
        )
        ssrq_server_log.warning(
            "Validation Error",
            extra={
                "path": request.url.path,
                "method": request.method,
                "status_code": 422,
                "lang": lang,
            },
            exc_info=(type(exc), exc, exc.__traceback__),
        )
        if request.url.path.startswith(API_PREFIX):
            return JSONResponse({"detail": exc.errors()}, status_code=422)
        else:
            return await ErrorViewModel(
                request=request,
                lang=lang,
                status_code=422,
            ).to_html()

    @app.exception_handler(Exception)
    async def exception_handler(request: Request, exc: Exception):
        """Catch-all for unhandled exceptions (500); log ERROR; return JSON for API paths, HTML otherwise."""
        lang = await get_lang(
            x_lang=request.headers.get("x-lang"), lang=request.query_params.get("lang")
        )
        ssrq_server_log.error(
            "Internal Server Error",
            extra={
                "path": request.url.path,
                "method": request.method,
                "status_code": 500,
                "lang": lang,
            },
            exc_info=(type(exc), exc, exc.__traceback__),
        )
        if request.url.path.startswith(API_PREFIX):
            return JSONResponse({"detail": "Internal Server Error"}, status_code=500)
        else:
            return await ErrorViewModel(
                request=request,
                lang=lang,
                status_code=500,
            ).to_html()
