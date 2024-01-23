import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)


@pytest.mark.asyncio_cooperative
@pytest.mark.depends_on_data
async def test_keys_in_occurences_list_all(execute_xquery: xquery_tester):
    """Test the keys returned keys in occurences_list_all."""
    xquery = build_query(
        modules=[
            xquery_modules["occurrences-list"],
        ],
        query_body=f"""let $keys := ("keywords", "lemmata", "persons", "places")
        let $result := occurrences-list:all()
        return
            every $key in $keys satisfies $key = map:keys($result) and exists($result($key))
        """,  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)
