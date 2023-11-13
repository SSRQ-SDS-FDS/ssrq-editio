import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "date, expected",
    [("2023-03-01", "2023"), ("1087-09-01", "1087"), ("1983", "1983")],
)
async def test_simple_idno_parsing(execute_xquery: xquery_tester, date: str, expected: str):
    """Test the parsing of idnos."""
    xquery = build_query(
        modules=[xquery_modules["date-parser"]],
        query_body=f"date-parser:extract-year(<date when='{date}'/>/@when)",
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)
