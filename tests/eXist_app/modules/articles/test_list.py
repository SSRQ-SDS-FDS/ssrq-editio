import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)

EXPECTED_KANTONS = 5
EXPECTED_NE_VOLUMES = 3


@pytest.mark.asyncio
async def test_number_of_kantons_from_list_by_kanton_and_volume(
    execute_xquery: xquery_tester,
):
    """Tests the number of kantons returned ba the articles-list:by-kanton-and-volume()
    function. Tested against editio-data."""
    xquery = build_query(
        modules=[xquery_modules["articles-list"]],
        query_body="""count(articles-list:by-kanton-and-volume()//kanton[parent::docs])""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected_result=EXPECTED_KANTONS)


@pytest.mark.asyncio
async def test_number_of_volumes_per_kanton(
    execute_xquery: xquery_tester,
):
    """Tests the number of kantons returned ba the articles-list:by-kanton-and-volume()
    function. Tested against editio-data."""
    xquery = build_query(
        modules=[xquery_modules["articles-list"]],
        query_body="""count(articles-list:by-kanton-and-volume()//kanton[@xml:id = "NE"]/volume)""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected_result=EXPECTED_NE_VOLUMES)


@pytest.mark.asyncio
async def test_every_doc_belongs_to_volume(
    execute_xquery: xquery_tester,
):
    """Test the grouping of docs by volume. Every doc should belong to a volume."""
    xquery = build_query(
        modules=[xquery_modules["articles-list"]],
        query_body="""let $results :=
        for $volume in articles-list:by-kanton-and-volume()//kanton[@xml:id = "NE"]/volume
        return
            every $doc in $volume//docs satisfies contains($doc/@xml:id, $volume/@xml:id)
        return every $result in $results satisfies $result
        """,  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected_result=True)
