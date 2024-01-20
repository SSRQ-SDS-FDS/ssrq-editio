import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)


@pytest.mark.asyncio_cooperative
async def test_rewrite_params(
    execute_xquery: xquery_tester,
):
    """Test if params are rewritten as expected."""
    xquery = build_query(
        modules=[xquery_modules["ssrq-router"]],
        query_body="""let $initial-request := map {"path": 'bar', "parameters":
                                                map {"kanton": "SG/",
                                                   "volume": "NE_4/"}
                                            }
                      let $rewritten-request :=
                        ssrq-router:rewrite-params($initial-request, $ssrq-router:params-to-rewrite,
                        $ssrq-router:id-param-name)
        return
            map:keys($rewritten-request) = ("path", "parameters") and
            map:keys($rewritten-request?parameters) = ("kanton", "volume") and
            $rewritten-request?parameters?kanton = "SG" and
            $rewritten-request?parameters?volume = "NE_4"
        """,  # noqa,
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)
