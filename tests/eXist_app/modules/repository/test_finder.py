import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)


@pytest.mark.asyncio_cooperative
async def test_find_articles(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["finder"]],
        query_body="""every $doc in find:regular-articles() satisfies
        $doc[not(@type)][.//tei:idno[ancestor::tei:seriesStmt][matches(., 'SSRQ|SDS|FDS')]]""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)


@pytest.mark.asyncio_cooperative
async def test_find_paratextual_documents(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["finder"]],
        query_body="""every $doc in find:paratextual-documents() satisfies
        $doc[@type][.//tei:idno[ancestor::tei:seriesStmt][matches(., 'SSRQ|SDS|FDS')]]""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "idno, expected",
    [("SSRQ-SG-III_4-1-1", 1), ("Foo-bar", 0)],
)
async def test_find_by_idno_against_editio_data(
    execute_xquery: xquery_tester, idno: str, expected: int
):
    xquery = build_query(
        modules=[xquery_modules["finder"]],
        query_body=f"""let $doc := find:article-by-idno("{idno}")
        return
            count($doc)""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "idno_fragment, full_idno",
    [
        ("SG-III_4-1-1", "SSRQ-SG-III_4-1-1"),
        ("I_2_8-11.0-1", "SSRQ-FR-I_2_8-11.0-1"),
        ("NE-3-6-1", "SDS-NE-3-6-1"),
        ("NE-4-1.A.1-1", "SDS-NE-4-1.A.1-1"),
        ("Foo-bar", None),
    ],
)
async def test_find_article_by_idno_ending(
    execute_xquery: xquery_tester, idno_fragment: str, full_idno: str | None
):
    xquery = build_query(
        modules=[xquery_modules["finder"]],
        query_body=f"""let $doc := find:article-by-idno-ending("{idno_fragment}")
        return
            {'$doc//tei:seriesStmt/tei:idno/string() = ' + f"'{full_idno}'" if full_idno is not None else 'empty($doc)'}""",  # noqa
    )

    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "lang, expected",
    [("de", True), ("en", True), ("fr", True), ("it", True), ("foo", False)],
)
async def test_find_i18n_catalogue_by_lang(
    execute_xquery: xquery_tester, lang: str, expected: bool
):
    xquery = build_query(
        modules=[xquery_modules["finder"]],
        query_body=f"""find:i18n-catalogue-by-lang('{lang}') => exists()""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)
