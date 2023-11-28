import pytest

from httpx import codes

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
    unquote_xquery_result,
)


@pytest.mark.asyncio_cooperative
async def test_create_url_base_for_link(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["template-utils"], xquery_modules["views"]],
        query_body="""let $req := map { 'parameters': map { 'foo': 'baz', 'bar': 'baz' } }
        let $input := <a href="{{foo}}/hello/baz/{{bar}}">foo</a>
        let $model := map{'configuration': views:get-template-config($req)}
        return
            template-utils:create-url-base-for-link($input/@href, $model)
            """,  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, "baz/hello/baz/baz")


@pytest.mark.asyncio_cooperative
async def test_find_and_replace_parts_from_link_template(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["template-utils"]],
        query_body="""let $input := <a href="{{app}}/{{volume}}/baz/{{volume}}">foo</a>
        return
            template-utils:find-and-replace-parts-from-link-template($input/@href)
            """,  # noqa
    )
    response = await execute_xquery(xquery)

    assert response.status_code == codes.OK

    assert {unquote_xquery_result(i) for i in response.text.split("\n") if i != ""} == {
        "app",
        "volume",
    }
