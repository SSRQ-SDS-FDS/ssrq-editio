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


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "idno, expected",
    [("SSRQ-SG-III_4-1-1", 1), ("Foo-bar", 0)],
)
async def test_find_by_idno_against_editio_data(
    execute_query: xquery_tester, idno: str, expected: int
):
    xquery = build_query(
        modules=[xquery_modules["finder"]],
        query_body=f"""let $doc := find:article-by-idno("{idno}")
        return
            count($doc) = {expected}""",  # noqa
    )
    response = await execute_query(xquery)

    assert response.status_code == 200

    assert response.text.replace('"', "") == "true()"
