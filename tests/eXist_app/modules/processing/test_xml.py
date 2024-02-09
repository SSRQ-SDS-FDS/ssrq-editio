import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)


@pytest.mark.asyncio_cooperative
async def test_get_subsections(
    execute_xquery: xquery_tester,
):
    """Test if params are rewritten as expected."""
    xquery = build_query(
        modules=[xquery_modules["pxml"]],
        query_body="""let $xml := <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <div>
            <head>foo</head>
        </div>
        <div>bar</div>
        <div>
            <head>foo</head>
            <div>
                <head>foo</head>
            </div>
        </div>
        </TEI>
        return pxml:get-subsections($xml) => count()
        """,  # noqa,
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, 2)
