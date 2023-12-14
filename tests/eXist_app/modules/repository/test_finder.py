import pytest
from httpx import codes
from pytest_asyncio_cooperative import Lock

from tests.eXist_app.conftest import (
    assert_xquery_result,
    build_query,
    cast_query_result,
    unquote_xquery_result,
    xquery_modules,
    xquery_tester,
)

acess_lock = Lock()


@pytest.fixture(scope="function")
async def pdf_access_lock():
    async with acess_lock():
        yield


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


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "idno, expected",
    [("SSRQ-SG-III_4-lit", 1), ("Foo-bar", 0)],
)
async def test_find_paratext_by_idno_against_editio_data(
    execute_xquery: xquery_tester, idno: str, expected: int
):
    xquery = build_query(
        modules=[xquery_modules["finder"]],
        query_body=f"""let $doc := find:paratextual-document-by-idno("{idno}")
        return
            count($doc)""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "idno, expected_filename",
    [
        ("SSRQ-SG-III_4-1-1", "SG/III_4/1-1.pdf"),
        ("SSRQ-FR-I_2_8-11.0-1", "FR/I_2_8/11-1.pdf"),
        ("SSRQ-FR-I_2_8-11.1-1", "FR/I_2_8/11-1.pdf"),
        ("SDS-NE-4-1.A.1-1", "NE/4/1.A.1-1.pdf"),
    ],
)
async def test_find_pdf_by_idno_against_editio_data(
    execute_xquery: xquery_tester, idno: str, expected_filename: str | None, pdf_access_lock: Lock
):
    """Test if PDF is available, as expected, and if the filename is correct.

    Note:
        The access to the PDFs is locked, so that only one test can access the PDFs at a time.
        So we need the `pdf_access_lock` fixture here.
    """
    xquery = build_query(
        modules=[xquery_modules["config"], xquery_modules["finder"], xquery_modules["ssrq-cache"]],
        query_body=f"""let $doc:= ssrq-cache:load-from-static-cache-by-id($config:static-cache-path, $config:static-docs-list, "{idno}")
        let $res := find:pdf-by-idno("{idno}", $doc)
        return
            ($res?available, $res?filename)""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert response.status_code == codes.OK

    result = [unquote_xquery_result(i) for i in response.text.split("\n") if i != ""]

    if expected_filename is not None:
        assert cast_query_result(result[0], True)
        assert (
            cast_query_result(result[1].replace("/exist/apps/ssrq/", ""), expected_filename)
            == expected_filename
        )
    else:
        assert not cast_query_result(result[0], False)


@pytest.mark.asyncio_cooperative
async def test_find_articles_by_path(
    execute_xquery: xquery_tester,
):
    """Test if the correct number of articles is found for a given path."""
    xquery = build_query(
        modules=[xquery_modules["config"], xquery_modules["finder"]],
        query_body="""find:articles-by-path($config:data-root || '/SG/SG_III_4') => count()""",  # noqa
    )

    assert_xquery_result(await execute_xquery(xquery), 259)

@pytest.mark.asyncio_cooperative
async def test_construct_path_from_kanton_and_volume(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["finder"]],
        query_body="""find:construct-path-from-kanton-and-volume('SG', 'III_4')""",  # noqa
    )

    assert_xquery_result(await execute_xquery(xquery), "/db/apps/ssrq/editio-data/SG/SG_III_4")
