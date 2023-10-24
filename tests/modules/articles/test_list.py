import pytest

from tests.conftest import build_query, xquery_modules, xquery_tester

EXPECTED_KANTONS = 5
EXPECTED_NE_VOLUMES = 3


@pytest.mark.asyncio
async def test_number_of_kantons_from_list_by_kanton_and_volume(
    execute_query: xquery_tester,
):
    """Tests the number of kantons returned ba the articles-list:by-kanton-and-volume()
    function. Tested against editio-data."""
    xquery = build_query(
        modules=[xquery_modules["articles-list"]],
        query_body="""count(articles-list:by-kanton-and-volume()//kanton[parent::docs])""",  # noqa
    )
    response = await execute_query(xquery)

    assert response.status_code == 200
    assert int(response.text.replace('"', "")) == EXPECTED_KANTONS


@pytest.mark.asyncio
async def test_number_of_volumes_per_kanton(
    execute_query: xquery_tester,
):
    """Tests the number of kantons returned ba the articles-list:by-kanton-and-volume()
    function. Tested against editio-data."""
    xquery = build_query(
        modules=[xquery_modules["articles-list"]],
        query_body="""count(articles-list:by-kanton-and-volume()//kanton[@xml:id = "NE"]/volume)""",  # noqa
    )
    response = await execute_query(xquery)

    assert response.status_code == 200
    assert int(response.text.replace('"', "")) == EXPECTED_NE_VOLUMES
