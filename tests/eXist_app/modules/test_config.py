import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "name, expected",
    [
        ("app-root", "/db/apps/ssrq"),
        ("data-root", "/db/apps/ssrq/editio-data"),
        ("temp-root", "/db/apps/ssrq/temp"),
        ("odd-root", "/db/apps/ssrq/resources/odd"),
    ],
)
async def test_config_variables(execute_xquery: xquery_tester, name: str, expected: str):
    """Test if the config variables are set / assigned correctly."""
    xquery = build_query(
        modules=[xquery_modules["config"]],
        query_body=f"$config:{name}",
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)
