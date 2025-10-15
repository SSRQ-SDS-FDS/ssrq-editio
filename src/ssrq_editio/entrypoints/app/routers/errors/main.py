from fastapi import FastAPI, Request
from fastapi.exceptions import HTTPException, RequestValidationError, StarletteHTTPException
from fastapi.responses import JSONResponse
from ssrq_utils.lang.display import Lang

from ssrq_editio.entrypoints.app.views.models.error import ErrorViewModel

API_PREFIX = "/api"


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(StarletteHTTPException)
    async def starlette_http_exc(request: Request, exc: StarletteHTTPException):
        if request.url.path.startswith(API_PREFIX):
            return JSONResponse({"detail": exc.detail}, status_code=exc.status_code)
        else:
            return await ErrorViewModel(
                request=request,
                lang=Lang.DE,
                status_code=exc.status_code,
            ).to_html()

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException):
        if request.url.path.startswith(API_PREFIX):
            return JSONResponse({"detail": exc.detail}, status_code=exc.status_code)
        else:
            return await ErrorViewModel(
                request=request,
                lang=exc.detail.get("lang", Lang.DE) if isinstance(exc.detail, dict) else Lang.DE,
                status_code=exc.status_code,
            ).to_html()

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        if request.url.path.startswith(API_PREFIX):
            return JSONResponse({"detail": exc.errors()}, status_code=422)
        else:
            return await ErrorViewModel(
                request=request,
                lang=Lang.DE,
                status_code=422,
            ).to_html()

    @app.exception_handler(Exception)
    async def unhandled(request: Request, exc: Exception):
        if request.url.path.startswith(API_PREFIX):
            return JSONResponse({"detail": "Internal Server Error"}, status_code=500)
        else:
            return await ErrorViewModel(
                request=request, lang=Lang.DE, status_code=getattr(exc, "status_code", 500)
            ).to_html()
