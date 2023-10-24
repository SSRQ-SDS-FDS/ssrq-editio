from typing import Awaitable
import pytest
from cli import config
import httpx
from collections.abc import Callable

TEI_NS = "http://www.tei-c.org/ns/1.0"

xquery_modules: dict[str, tuple[str, str, str]] = {
    "articles-list": (
        "articles-list",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/list",
        "/db/apps/ssrq/modules/articles/list.xqm",
    ),
    "config": (
        "config",
        "http://www.tei-c.org/tei-simple/config",
        "/db/apps/ssrq/modules/config.xqm",
    ),
    "date-parser": (
        "date-parser",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/date",
        "/db/apps/ssrq/modules/parser/date.xqm",
    ),
    "finder": (
        "find",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder",
        "/db/apps/ssrq/modules/repository/finder.xqm",
    ),
    "idno-parser": (
        "idno-parser",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/idno",
        "/db/apps/ssrq/modules/parser/idno.xqm",
    ),
    "ssrq-cache": (
        "ssrq-cache",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache",
        "/db/apps/ssrq/modules/repository/cache.xqm",
    ),
}


def build_query(modules: list[tuple[str, str, str]], query_body: str) -> str:
    module_imports = " ".join(
        [
            f'import module namespace {name}="{ns}" at "{loc}";'
            for name, ns, loc in modules
        ]
    )
    return " ".join(
        [
            'xquery version "3.1";',
            f'declare namespace tei="{TEI_NS}";',
            module_imports,
            query_body,
        ]
    )


xquery_tester = Callable[[str], Awaitable[httpx.Response]]


@pytest.hookimpl
def pytest_sessionstart(session):
    """Runs before the first test is executed – checks if the editio is running."""
    try:
        assert (
            httpx.get(f"http://localhost:{config.EDITIO_PORT}/exist/").status_code
            <= 400
        )
    except Exception:
        pytest.exit(
            reason="eXist-DB is not running – run 'editio start' first",
            returncode=1,
        )


@pytest.fixture(scope="session")
def exist_execute_url() -> str:
    return f"http://localhost:{config.EDITIO_PORT}/exist/apps/atom-editor/execute"


@pytest.fixture(scope="session")
def execute_query(exist_execute_url: str) -> xquery_tester:
    async def _execute(query: str) -> httpx.Response:
        headers = {"Content-Type": "application/xml"}
        params = {
            "base": "xmldb:exist://__new__2",
            "qu": query.replace("\n", " "),  # Inlining the query
            "output": "adaptive",
        }
        return httpx.post(exist_execute_url, headers=headers, params=params)

    return _execute
