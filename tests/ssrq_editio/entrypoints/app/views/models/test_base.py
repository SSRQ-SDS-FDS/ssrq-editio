import pytest
from fastapi.responses import HTMLResponse
from ssrq_utils.lang.display import Lang
from starlette.requests import Request

from ssrq_editio.entrypoints.app.views.models.base import (
    get_view_response_cache,
    serve_html_response,
)


class DummyView:
    def __init__(self, request: Request, body: str, status_code: int = 200):
        self.request = request
        self.lang = Lang.DE
        self._body = body
        self._status_code = status_code
        self.to_html_calls = 0

    async def _to_html(self) -> HTMLResponse:
        self.to_html_calls += 1
        return HTMLResponse(content=self._body, status_code=self._status_code)


def _request(method: str = "GET", path: str = "/dummy") -> Request:
    return Request(
        {
            "type": "http",
            "http_version": "1.1",
            "method": method,
            "scheme": "http",
            "path": path,
            "query_string": b"",
            "headers": [(b"host", b"testserver")],
            "client": ("127.0.0.1", 8000),
            "server": ("testserver", 80),
        }
    )


@pytest.fixture(autouse=True)
def clear_view_cache() -> None:
    get_view_response_cache().clear()


@pytest.mark.anyio
async def test_serve_html_response_uses_cache_for_successful_get_requests() -> None:
    first_view = DummyView(_request(), body="first")
    first_response = await serve_html_response(first_view)

    assert first_response.body == b"first"
    assert first_view.to_html_calls == 1

    second_view = DummyView(_request(), body="second")
    second_response = await serve_html_response(second_view)

    assert second_response.body == b"first"
    assert second_view.to_html_calls == 0


@pytest.mark.anyio
async def test_serve_html_response_does_not_cache_error_responses() -> None:
    error_view = DummyView(_request(), body="error", status_code=500)
    error_response = await serve_html_response(error_view)

    assert error_response.status_code == 500
    assert error_view.to_html_calls == 1

    ok_view = DummyView(_request(), body="ok", status_code=200)
    ok_response = await serve_html_response(ok_view)

    assert ok_response.status_code == 200
    assert ok_response.body == b"ok"
    assert ok_view.to_html_calls == 1


@pytest.mark.anyio
async def test_serve_html_response_skips_cache_for_non_get_requests() -> None:
    first_view = DummyView(_request(method="POST"), body="first")
    first_response = await serve_html_response(first_view)

    assert first_response.body == b"first"
    assert first_view.to_html_calls == 1

    second_view = DummyView(_request(method="POST"), body="second")
    second_response = await serve_html_response(second_view)

    assert second_response.body == b"second"
    assert second_view.to_html_calls == 1
