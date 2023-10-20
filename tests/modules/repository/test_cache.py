import pytest

from tests.conftest import build_query, xquery_modules, xquery_tester
from cli import config


@pytest.mark.asyncio
async def test_cache_can_create_static_dir(execute_query: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DEV_DUMMY_PASSWORD}"),
        ssrq-cache:create-static-cache-dir("/db/apps", "dummy", "admin", "admin"))[last()]""",  # noqa
    )
    response = await execute_query(xquery)

    assert response.status_code == 200
    assert response.text == "true()"

    # remove dummy collection after test
    await execute_query(
        build_query(
            modules=[xquery_modules["ssrq-cache"]],
            query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DEV_DUMMY_PASSWORD}"),
        xmldb:remove("/db/apps/dummy"))[last()]""",  # noqa
        )
    )


@pytest.mark.asyncio
async def test_dynamic_cache_creation_and_deletion(execute_query: xquery_tester):
    """The cache should be created and deletion method will return true
    if it is and delete it afterwards. We're testing two methods here."""
    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DEV_DUMMY_PASSWORD}"),
        ssrq-cache:create-dynamic-cache("foo", 3, 3), ssrq-cache:destroy-cache-if-exists("foo"))[last()]""",  # noqa
    )
    response = await execute_query(xquery)

    assert response.status_code == 200
    assert response.text == "true()"


@pytest.mark.asyncio
async def test_cache_key_creation(execute_query: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""ssrq-cache:create-unique-cache-key("foo")""",  # noqa
    )
    response = await execute_query(xquery)

    assert response.status_code == 200
    response_with_cleared_quotes = response.text.replace('"', "")
    assert response_with_cleared_quotes.startswith("foo_")


@pytest.mark.asyncio
async def test_store_and_get_from_dynamic_cache(execute_query: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DEV_DUMMY_PASSWORD}"),
        ssrq-cache:create-dynamic-cache("foo", 15, 999),
        ssrq-cache:store-in-dynamic-cache("foo", "bla_", "bar"))[last()]""",  # noqa
    )

    response = await execute_query(xquery)

    assert response.status_code == 200
    response_with_cleared_quotes = response.text.replace('"', "")
    assert response_with_cleared_quotes.startswith("bla_")

    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DEV_DUMMY_PASSWORD}"),
        ssrq-cache:load-from-dynamic-cache("foo", "bla_"))[last()]""",  # noqa
    )

    response = await execute_query(xquery)

    assert response.status_code == 200
    response_with_cleared_quotes = response.text.replace('"', "")
    assert response_with_cleared_quotes == "bar"

    # remove cache after test
    await execute_query(
        build_query(
            modules=[xquery_modules["ssrq-cache"]],
            query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DEV_DUMMY_PASSWORD}"),
        ssrq-cache:destroy-cache-if-exists("foo"))""",  # noqa
        )
    )
