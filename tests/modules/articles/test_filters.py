import pytest

from tests.conftest import build_query, xquery_modules, xquery_tester

PERIOD_MIN = 1050
PUBDATE_MIN = 2017


@pytest.mark.asyncio
async def test_create_pubdate_range_against_editio_data(
    execute_query: xquery_tester,
):
    """Tests the number of kantons returned ba the articles-list:by-kanton-and-volume()
    function. Tested against editio-data."""
    xquery = build_query(
        modules=[xquery_modules["articles-filters"], xquery_modules["finder"]],
        query_body="""let $range := articles-filters:create-pubdate-range(find:regular-articles())
        return
            $range//min/text()""",  # noqa
    )
    response = await execute_query(xquery)

    assert response.status_code == 200
    assert int(response.text.replace('"', "")) == PUBDATE_MIN


@pytest.mark.asyncio
async def test_create_period_range_against_editio_data(
    execute_query: xquery_tester,
):
    xquery = build_query(
        modules=[xquery_modules["articles-filters"], xquery_modules["finder"]],
        query_body="""let $range := articles-filters:create-period-range(find:regular-articles())
        return
            $range//min/text()""",  # noqa
    )
    response = await execute_query(xquery)

    assert response.status_code == 200
    assert int(response.text.replace('"', "")) == PERIOD_MIN


@pytest.mark.asyncio
async def test_create_archive_list_returns_archives(
    execute_query: xquery_tester,
):
    """Tests the number of kantons returned ba the articles-list:by-kanton-and-volume()
    function. Tested against editio-data."""
    xquery = build_query(
        modules=[xquery_modules["articles-filters"], xquery_modules["finder"]],
        query_body="""let $archives := articles-filters:create-archive-list(find:regular-articles())
        return
            count($archives//archive) = count(distinct-values($archives//text()))""",  # noqa
    )
    response = await execute_query(xquery)

    assert response.status_code == 200
    assert response.text.replace('"', "") == "true()"
