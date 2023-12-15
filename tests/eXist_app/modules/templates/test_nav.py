import pytest

from tests.eXist_app.conftest import (
    assert_xquery_result,
    build_query,
    xquery_modules,
    xquery_tester,
)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "input_path, expected_result",
    [
        ("/SG/", "SG"),
        ("/SG/III_4", "SG III/4"),
        ("/SG/III_4/1-1.html", "SG III/4 1"),
        ("/NE/4/1.A.1-1.html", "NE 4 1.A.1"),
        ("/ZH/NF_I_1_3", "ZH NF I/1/3"),
        ("/about/partners.html", "about partners"),
        ("/about/api.html", "about api"),
    ],
)
async def test_create_url_base_for_link(
    execute_xquery: xquery_tester, input_path: str, expected_result: str
):
    """Test the text-content, which is returned by the `nav:breadcrumbs` function."""
    xquery = build_query(
        modules=[xquery_modules["nav"], xquery_modules["views"]],
        query_body=f"""let $req := map {{ 'parameters': map {{ 'request-path': '{input_path}' }} }}
            let $model := map {{ 'configuration': views:get-template-config($req) }}
            return
                string-join(nav:breadcrumbs(<li/>, $model) ! ./string(), ' ')
            """,  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected_result)
