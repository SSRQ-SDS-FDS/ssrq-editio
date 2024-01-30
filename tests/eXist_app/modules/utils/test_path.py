import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "name, expected",
    [
        ("/SG", False),
        ("/SG/III_4/", False),
        ("/SG/III_4/intro.html", False),
        ("intro.xml", True),
    ],
)
async def test_is_file_name(execute_xquery: xquery_tester, name: str, expected: bool):
    xquery = build_query(
        modules=[xquery_modules["path"]],
        query_body=f"path:is-file-name('{name}')",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "path, expected",
    [
        ("SG", "SG"),
        ("/SG", "SG"),
        ("/SG/III_4/", ("SG", "III_4")),
    ],
)
async def test_path_tokenize(
    execute_xquery: xquery_tester, path: str, expected: str | tuple[str, ...]
):
    xquery = build_query(
        modules=[xquery_modules["path"]],
        query_body=f"""path:tokenize("{path}")""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)
