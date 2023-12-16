import pytest
from httpx import codes
from pytest_asyncio_cooperative import Lock

from tests.eXist_app.conftest import (
    assert_xquery_result,
    build_query,
    cast_query_result,
    unquote_xquery_result,
    xquery_modules,
    xquery_tester,
)

acess_lock = Lock()


@pytest.fixture(scope="function")
async def pdf_access_lock():
    async with acess_lock():
        yield


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    ("input", "expected"),
    [
        ("true", "yes"),
        ("false", "no"),
    ],
)
async def test_convert_bool_to_lucene_value(
    execute_xquery: xquery_tester, input: str, expected: str
):
    xquery = build_query(
        modules=[xquery_modules["query"]],
        query_body=f"query:convert-bool-to-lucene-value({input}())",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)
