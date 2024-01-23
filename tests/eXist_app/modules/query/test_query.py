import pytest

from tests.eXist_app.conftest import (
    assert_xquery_result,
    build_query,
    xquery_modules,
    xquery_tester,
)


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


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    ("input", "expected"),
    [
        ("()", ""),
        ("'bar'", "title:bar OR idno:bar"),
    ],
)
async def test_build_field_query(execute_xquery: xquery_tester, input: str, expected: str):
    xquery = build_query(
        modules=[xquery_modules["query"]],
        query_body=f"query:build-field-query({input}, ('title', 'idno'), 'OR')",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)
