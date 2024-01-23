import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)


@pytest.mark.asyncio_cooperative
@pytest.mark.depends_on_data
async def test_documents_list(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["documents"]],
        query_body="""let $list := documents:list(<div/>, map{}, 'SG', 'III_4', 1, 15, ())
        return
            (
                $list instance of element(section),
                count($list/*[@class = 'document-info'])
            )""",  # noqa
    )
    response = await execute_xquery(xquery)

    # print(response.text)

    assert_xquery_result(response, (True, 15))


@pytest.mark.asyncio_cooperative
@pytest.mark.depends_on_data
async def test_reorder_hits_and_filter(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["documents"], xquery_modules["query"]],
        query_body=f"""let $examples := collection('/db/apps/ssrq')//tei:TEI[starts-with(.//tei:idno, 'SSRQ-FR-I_2_8-4.')]
        let $hits := query:articles-by-title-or-idno($examples, ())
        return
            documents:reorder-hits-and-filter($hits)
            => count()""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, 1)
