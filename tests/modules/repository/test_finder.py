import pytest

from tests.conftest import build_query, xquery_modules, xquery_tester


@pytest.mark.asyncio
async def test_find_articles(execute_query: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["finder"]],
        query_body="""every $doc in find:regular-articles() satisfies
        $doc[not(@type)][.//tei:idno[ancestor::tei:seriesStmt][matches(., 'SSRQ|SDS|FDS')]]""",  # noqa
    )
    response = await execute_query(xquery)

    assert response.status_code == 200
    assert bool(response.text)


@pytest.mark.asyncio
async def test_find_paratextual_documents(execute_query: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["finder"]],
        query_body="""every $doc in find:paratextual-documents() satisfies
        $doc[@type][.//tei:idno[ancestor::tei:seriesStmt][matches(., 'SSRQ|SDS|FDS')]]""",  # noqa
    )
    response = await execute_query(xquery)

    assert response.status_code == 200
    assert bool(response.text)
