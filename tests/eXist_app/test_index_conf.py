import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "idno, expected",
    [("SSRQ-SG-III_4-1-1", True), ("BAC 011.0030", True), ("QZYT", False)],
)
async def test_if_range_index_for_idno_exists(
    execute_xquery: xquery_tester, idno: str, expected: bool
):
    xquery = build_query(
        modules=[xquery_modules["config"]],
        query_body=f"""collection($config:data-root)/tei:TEI
        => range:matches("{idno}")
        => exists()""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "attr, example_value, expected",
    [
        ("@key", "close", True),
        ("@type", "deadline", True),
        ("@xml:lang", "de", True),
    ],
)
async def test_if_range_index_attr_exists(
    execute_xquery: xquery_tester, attr: str, example_value: str, expected: bool
):
    xquery = build_query(
        modules=[xquery_modules["config"]],
        query_body=f"""collection($config:app-root)//{attr}
        => range:matches("{example_value}")
        => exists()""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)
