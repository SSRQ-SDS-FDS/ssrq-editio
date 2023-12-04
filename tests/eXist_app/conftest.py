from typing import Awaitable
from parsel import Selector
import pytest
from cli import config
import httpx
from collections.abc import Callable
from cli.config import DOCKER_DEV_SETTINGS

TEI_NS = "http://www.tei-c.org/ns/1.0"

xquery_modules: dict[str, tuple[str, str, str]] = {
    "articles-filters": (
        "articles-filters",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/filters",
        "/db/apps/ssrq/modules/articles/filters.xqm",
    ),
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
    "documents": (
        "documents",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/documents",
        "/db/apps/ssrq/modules/templates/documents.xqm",
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
    "kantons": (
        "kantons",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/kantons",
        "/db/apps/ssrq/modules/templates/kantons.xqm",
    ),
    "occurrences-find": (
        "occurrences-find",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/occurrences/find",
        "/db/apps/ssrq/modules/occurrences/find.xqm",
    ),
    "occurrences-list": (
        "occurrences-list",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/occurrences/list",
        "/db/apps/ssrq/modules/occurrences/list.xqm",
    ),
    "pagination": (
        "pagination",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/pagination",
        "/db/apps/ssrq/modules/templates/pagination.xqm",
    ),
    "ssrq-cache": (
        "ssrq-cache",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache",
        "/db/apps/ssrq/modules/repository/cache.xqm",
    ),
    "ssrq-router": (
        "ssrq-router",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/router",
        "/db/apps/ssrq/modules/router.xql",
    ),
    "template-utils": (
        "template-utils",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/utils",
        "/db/apps/ssrq/modules/templates/template-utils.xqm",
    ),
    "views": (
        "views",
        "http://ssrq-sds-fds.ch/exist/apps/ssrq/views",
        "/db/apps/ssrq/modules/views.xqm",
    ),
}


def build_query(modules: list[tuple[str, str, str]], query_body: str) -> str:
    """Builds a query from the given modules and query body.

    Args:
        modules (list[tuple[str, str, str]]): The modules to import
        query_body (str): The query body

    Returns:
        str: The query"""
    module_imports = " ".join(
        [f'import module namespace {name}="{ns}" at "{loc}";' for name, ns, loc in modules]
    )
    return " ".join(
        [
            'xquery version "3.1";',
            f'declare namespace tei="{TEI_NS}";',
            module_imports,
            query_body,
        ]
    )


class XPathAssertion:
    xpath: str
    expected_result: bool | int | str | float | list | None

    def __init__(self, xpath: str, expected_result: str | list[str] | None):
        self.xpath = xpath
        self.expected_result = expected_result

    def query_and_assert(self, xml: Selector):
        xpath_result = xml.xpath(self.xpath)
        match self.expected_result:
            case None:
                assert len(xpath_result) == 0
            case list(_):
                assert xpath_result.getall() == self.expected_result
            case _:
                assert xpath_result.get() == self.expected_result


def assert_xquery_result(
    result: httpx.Response,
    expected_result: bool | int | str | float | XPathAssertion | list[XPathAssertion],
    expected_code: httpx.codes = httpx.codes.OK,
):
    """Asserts the result of an XQuery.

    Args:
        result (httpx.Response): The result of the XQuery
        expected_result (bool | int | str | float | XPathAssertion | list[XPathAssertion]): The expected result
        expected_code (httpx.codes, optional): The expected HTTP status code. Defaults to httpx.codes.OK.

    Raises:
        AssertionError: If the result is not equal to the expected result"""

    assert result.status_code == expected_code

    if isinstance(expected_result, XPathAssertion):
        expected_result.query_and_assert(Selector(result.text, type="xml"))
        return

    if isinstance(expected_result, list):
        xml_selector = Selector(result.text, type="xml")
        for assertion in expected_result:
            assertion.query_and_assert(xml_selector)
        return

    assert (
        cast_query_result(
            result=unquote_xquery_result(result=result.text),
            expected_result=expected_result,
        )
        == expected_result
    )


def unquote_xquery_result(result: str) -> str:
    """Removes the quotes from the result of an XQuery.

    Args:
        result (str): The result of the XQuery

    Returns:
        str: The unquoted result"""
    if result.startswith('"'):
        result = result[1:]
    if result.endswith('"'):
        result = result[:-1]
    return result


def cast_query_result(
    result: str,
    expected_result: bool | int | str | float,
):
    """Casts the result of an XQuery to the expected type.

    Args:
        result (str): The result of the XQuery
        expected_result (bool | int | str | float): The expected result type

    Raises:
        ValueError: If the result could not be casted to the expected type

    Returns:
        bool | int | str | float: The casted result"""
    match result, expected_result:
        case "true()" | "false()", bool(expected_result):
            return True if result == "true()" else False
        case _, int(expected_result):
            return int(result)
        case _, float(expected_result):
            return float(result)
        case _, str(expected_result):
            return result
        case _, _:
            raise ValueError(
                f"Could not cast result '{result}' to expected type '{type(expected_result)}'"
            )


xquery_tester = Callable[[str], Awaitable[httpx.Response]]


@pytest.hookimpl
def pytest_sessionstart(session):
    """Runs before the first test is executed – checks if the editio is running."""
    try:
        assert (
            httpx.get(f"http://localhost:{config.DOCKER_DEV_SETTINGS.dev.port}/exist/").status_code
            <= 400
        )
    except Exception:
        pytest.exit(
            reason="eXist-DB is not running – run 'editio start' first",
            returncode=1,
        )


@pytest.fixture(scope="session")
def exist_url() -> str:
    return f"http://localhost:{config.DOCKER_DEV_SETTINGS.dev.port}/exist/apps/atom-editor/execute"


@pytest.fixture(scope="session")
async def async_http_client():
    async with httpx.AsyncClient() as client:
        yield client


@pytest.fixture
def execute_xquery(async_http_client: httpx.AsyncClient, exist_url: str) -> xquery_tester:
    async def _execute(query: str) -> httpx.Response:
        return await async_http_client.post(
            exist_url,
            auth=httpx.BasicAuth(DOCKER_DEV_SETTINGS.dev.user, DOCKER_DEV_SETTINGS.dev.password),
            headers={"Content-Type": "application/xml"},
            params={
                "base": "xmldb:exist://__new__2",
                "qu": query.replace("\n", " "),  # Inlining the query
                "output": "adaptive",
            },
            timeout=httpx.Timeout(10, connect=10),
            follow_redirects=True,
        )

    return _execute
