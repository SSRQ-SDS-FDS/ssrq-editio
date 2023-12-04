import pytest

from tests.eXist_app.conftest import (
    unquote_xquery_result,
    build_query,
    xquery_modules,
    xquery_tester,
)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    ("inputs", "expected"),
    [
        ([10, 10, 1], None),
        ([11, 10, 1], [1, 2]),
        ([70, 10, 1], [1, 2, 3, 4, 5, 6, 7]),
        ([140, 10, 3], [1, 2, 3, 4, 5, -1, 14]),
        ([140, 10, 5], [1, -1, 4, 5, 6, -1, 14]),
        ([140, 10, 14], [1, -1, 10, 11, 12, 13, 14]),
        ([185, 15, 6], [1, -1, 5, 6, 7, -1, 13]),
    ],
)
async def test_caclc_pagination(
    execute_xquery: xquery_tester, inputs: tuple[int, int, int], expected: None | list[int]
):
    """Algorithm should return correct pages numbers – aligned with pagination seven-pattern."""
    xquery = build_query(
        modules=[xquery_modules["pagination"]],
        query_body=f"""pagination:calc-pages({inputs[0]}, {inputs[1]} , {inputs[2]})""",  # noqa
    )
    response = await execute_xquery(xquery)

    if expected is not None:
        assert [int(i) for i in unquote_xquery_result(response.text).split("\n")] == expected
    else:
        assert response.text == ""
