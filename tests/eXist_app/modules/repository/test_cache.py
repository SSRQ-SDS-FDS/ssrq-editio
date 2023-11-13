import pytest
import pytest_asyncio

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)
from cli import config


@pytest_asyncio.fixture
async def teardown_dummy_collection(execute_xquery: xquery_tester):
    yield
    # remove dummy collection after test
    await execute_xquery(
        build_query(
            modules=[xquery_modules["ssrq-cache"]],
            query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DOCKER_DEV_SETTINGS.dev.password}"),
        xmldb:remove("/db/apps/dummy"))[last()]""",  # noqa
        )
    )


@pytest.mark.asyncio
async def test_cache_can_create_static_dir(
    execute_xquery: xquery_tester, teardown_dummy_collection
):
    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DOCKER_DEV_SETTINGS.dev.password}"),
        ssrq-cache:create-static-cache-dir("/db/apps", "dummy", "admin", "admin"))[last()]""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)


@pytest.mark.asyncio
async def test_cache_can_store_and_load_from_static_cache(
    execute_xquery: xquery_tester, teardown_dummy_collection
):
    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DOCKER_DEV_SETTINGS.dev.password}"),
        ssrq-cache:create-static-cache-dir("/db/apps", "dummy", "admin", "admin"),
        ssrq-cache:put-into-static-cache("/db/apps/dummy", "foo.xml", <hello xml:id="bar">baz</hello>))[last()]""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)

    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DOCKER_DEV_SETTINGS.dev.password}"),
        ssrq-cache:load-from-static-cache-by-id("/db/apps/dummy", "foo.xml", "bar"))[last()]""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, '<hello xml:id="bar">baz</hello>')


@pytest.mark.asyncio
async def test_dynamic_cache_creation_and_deletion(execute_xquery: xquery_tester):
    """The cache should be created and deletion method will return true
    if it is and delete it afterwards. We're testing two methods here."""
    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DOCKER_DEV_SETTINGS.dev.password}"),
        ssrq-cache:create-dynamic-cache("foo", 3, 3), ssrq-cache:destroy-dynamic-cache-if-exists("foo"))[last()]""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)


@pytest.mark.asyncio
async def test_cache_key_creation(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""ssrq-cache:create-unique-cache-key("foo") => starts-with("foo_")""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)


@pytest.mark.asyncio
async def test_store_and_get_from_dynamic_cache(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DOCKER_DEV_SETTINGS.dev.password}"),
        ssrq-cache:create-dynamic-cache("foo", 15, 999),
        ssrq-cache:store-in-dynamic-cache("foo", "bla_", "bar") => starts-with("bla_"))[last()]""",  # noqa
    )

    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)

    xquery = build_query(
        modules=[xquery_modules["ssrq-cache"]],
        query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DOCKER_DEV_SETTINGS.dev.password}"),
        ssrq-cache:load-from-dynamic-cache("foo", "bla_"))[last()]""",  # noqa
    )

    response = await execute_xquery(xquery)

    assert_xquery_result(response, "bar")

    # remove cache after test
    await execute_xquery(
        build_query(
            modules=[xquery_modules["ssrq-cache"]],
            query_body=f"""(xmldb:login("/db/apps", "admin", "{config.DOCKER_DEV_SETTINGS.dev.password}"),
        ssrq-cache:destroy-dynamic-cache-if-exists("foo"))""",  # noqa
        )
    )
