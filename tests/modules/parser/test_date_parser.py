import pytest
from parsel import Selector

from tests.conftest import build_query, xquery_modules, xquery_tester


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "date, expected",
    [
        ("2023-03-01", "2023"),
        ("1087-09-01", "1087"),
    ],
)
async def test_simple_idno_parsing(
    execute_query: xquery_tester, date: str, expected: str
):
    """Test the parsing of idnos."""
    xquery = build_query(
        modules=[xquery_modules["date-parser"]],
        query_body=f"date-parser:extract-year(<date when='{date}'/>/@when)",
    )
    response = await execute_query(xquery)

    assert response.status_code == 200

    assert response.text.replace('"', "") == expected
