import pytest

from httpx import codes

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
    unquote_xquery_result,
)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "tools, expected",
    [
        (None, False),
        ("bar", False),
        ("xml", True),
        ("bar,   xml, xquery", True),
    ],
)
async def test_toolbar_container_return_type(
    execute_xquery: xquery_tester, tools: str | None, expected: bool
):
    xquery = build_query(
        modules=[xquery_modules["toolbar"]],
        query_body=f"""let $toolbar := toolbar:container(<div/>, map{{}}, {f"\'{tools}\'" if tools else ()})
            return
                exists($toolbar)""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)


@pytest.mark.asyncio_cooperative
async def test_toolbar_get_known_tools(execute_xquery: xquery_tester):
    known_tools = "map {'xml': map {'function': toolbar:xml#1, 'position': 1}}"
    xquery = build_query(
        modules=[xquery_modules["toolbar"]],
        query_body=f"""let $known-tools := toolbar:get-known-tools('bar, xml', {known_tools})
            return
                count($known-tools)""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, 1)
