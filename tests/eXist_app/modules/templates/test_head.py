import pytest

from tests.eXist_app.conftest import (
    assert_xquery_result,
    build_query,
    xquery_modules,
    xquery_tester,
)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "lang, expected_title",
    [
        ("de", "SSRQ online"),
        ("en", "SLS online"),
    ],
)
async def test_head_page_title(
    execute_xquery: xquery_tester,
    lang: str,
    expected_title: str,
):
    "Test generated page title against expected title for different languages"
    xquery = build_query(
        modules=[xquery_modules["head"], xquery_modules["views"]],
        query_body=f"""let $config := map{{ 'configuration': views:get-template-config(map{{"parameters": map{{"lang": "{lang}"}}}})}}
        return
            head:page-title(<div/>, $config)/text()
        """,  # noqa
    )

    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected_title)


@pytest.mark.asyncio_cooperative
async def test_head_meta(
    execute_xquery: xquery_tester,
):
    "Test generated page title against expected title for different languages"
    xquery = build_query(
        modules=[xquery_modules["head"], xquery_modules["views"]],
        query_body="""head:meta(<div/>, map{})/@content/data(.)
        """,  # noqa
    )

    response = await execute_xquery(xquery)

    assert_xquery_result(response, "Schweizerische Rechtsquellen")
