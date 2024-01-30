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
        ("foo.xml", "foo"),
        ("bar/foo", ""),
        ("baz/bar/foo.html", "foo"),
    ],
)
async def test_get_filename(execute_xquery: xquery_tester, name: str, expected: str):
    xquery = build_query(
        modules=[xquery_modules["path"]],
        query_body=f"""path:get-filename("{name}")""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)


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


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "name, expected",
    [
        ("foo.xml", "xml"),
        ("bar.html", "html"),
    ],
)
async def test_extract_file_extension(execute_xquery: xquery_tester, name: str, expected: str):
    xquery = build_query(
        modules=[xquery_modules["path"]],
        query_body=f"""path:extract-file-extension("{name}")""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected)


@pytest.mark.asyncio_cooperative
async def test_remove_file_extension(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["path"]],
        query_body=f"""path:remove-file-extension("foo.html", "html")""",  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, "foo")
