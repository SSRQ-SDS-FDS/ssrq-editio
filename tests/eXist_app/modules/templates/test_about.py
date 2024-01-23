import pytest

from tests.eXist_app.conftest import (
    XPathAssertion,
    assert_xquery_result,
    build_query,
    xquery_modules,
    xquery_tester,
)


@pytest.mark.asyncio_cooperative
@pytest.mark.depends_on_data
async def test_list_partners_renders_section_for_each_block(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["about"]],
        query_body="""let $partners := about:list-partners(<div/>, map{})
        return
            <div>{$partners}</div>""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(
        response,
        expected_result=[
            XPathAssertion(xpath="count(//section)", expected_result="2.0"),
        ],
    )


@pytest.mark.asyncio_cooperative
@pytest.mark.depends_on_data
async def test_list_partners_renders_each_partner(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["about"], xquery_modules["config"], xquery_modules["finder"]],
        query_body="""let $list-of-partners := find:load-document-by-path(($config:misc-path, $config:partners))
        let $partners-rendered := <div>{about:list-partners(<div/>, map{})}</div>
        return
            count($partners-rendered//li)
            = count($list-of-partners//tei:valItem)""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)
