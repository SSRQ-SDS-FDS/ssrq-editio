import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)


@pytest.mark.asyncio_cooperative
async def test_documents_list(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["documents"]],
        query_body="""let $list := documents:list(<div/>, map{}, 'SG', 'III_4', 1, 15)
        return
            count($list?current-page-documents) = 15 and
            $list?total-documents = 259""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)
