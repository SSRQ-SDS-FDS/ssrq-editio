import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
    XPathAssertion,
)


@pytest.mark.asyncio_cooperative
async def test_simple_idno_parsing(execute_xquery: xquery_tester):
    """Test the parsing of idnos."""
    xquery = build_query(
        modules=[xquery_modules["idno-parser"]],
        query_body="idno-parser:parse-regular('SSRQ-SG-III_4-58-1')",
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(
        result=response,
        expected_result=[
            XPathAssertion(xpath="doc/text()", expected_result="58"),
            XPathAssertion(xpath="num/text()", expected_result="1"),
        ],
    )


@pytest.mark.asyncio_cooperative
async def test_idno_parsing_with_case(execute_xquery: xquery_tester):
    """Test the parsing of idnos."""
    xquery = build_query(
        modules=[xquery_modules["idno-parser"]],
        query_body="idno-parser:parse-regular('SSRQ-FR-I_2_8-87.2-1')",
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(
        result=response,
        expected_result=[
            XPathAssertion(xpath="volume/text()", expected_result="I_2_8"),
            XPathAssertion(xpath="case/text()", expected_result="87"),
            XPathAssertion(xpath="doc/text()", expected_result="2"),
        ],
    )


@pytest.mark.asyncio_cooperative
async def test_idno_parsing_with_case_and_opening(execute_xquery: xquery_tester):
    """Test the parsing of idnos."""
    xquery = build_query(
        modules=[xquery_modules["idno-parser"]],
        query_body="idno-parser:parse-regular('SDS-NE-4-1.A.1-1')",
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(
        result=response,
        expected_result=[
            XPathAssertion(xpath="volume/text()", expected_result="4"),
            XPathAssertion(xpath="case/text()", expected_result="1"),
            XPathAssertion(xpath="opening/text()", expected_result="A"),
        ],
    )


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    ("idno", "is_main"),
    [
        ("SSRQ-SG-III_4-58-1", True),
        ("SSRQ-FR-I_2_8-2.0-1", True),
        ("SSRQ-FR-I_2_8-2.1-1", False),
        ("SDS-NE-4-1.0-1", True),
        ("SDS-NE-4-1.A.1-1", False),
        ("SDS-NE-4-1.11-1", False),
    ],
)
async def test_idno_parsing_with_main_check(
    execute_xquery: xquery_tester, idno: str, is_main: bool
):
    """Test the result of the parsing and check if article is 'main'."""
    xquery = build_query(
        modules=[xquery_modules["idno-parser"]],
        query_body=f"idno-parser:parse('{idno}', true())?is-main",
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(
        result=response,
        expected_result=is_main,
    )


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    ("idno", "expected_output"),
    [
        ("SSRQ-FR-I_2_8-7.0-1", "SSRQ FR I/2/8 7.0"),
        ("SSRQ-FR-I_2_8-7.1-1", "SSRQ FR I/2/8 7.1"),
        ("SDS-NE-3-337-1", "SDS NE 3 337"),
        ("SDS-VD-D_1-10-1", "SDS VD D 1 10"),
        ("SSRQ-ZH-NF_I_1_3-1-1", "SSRQ ZH NF I/1/3 1"),
        ("SDS-NE-4-1.A.1-1", "SDS NE 4 1.A.1"),
    ],
)
async def test_print_idno(execute_xquery: xquery_tester, idno: str, expected_output: str):
    """Test the conversion of an idno to a human readable string."""
    xquery = build_query(
        modules=[xquery_modules["idno-parser"]],
        query_body=f"idno-parser:print('{idno}')",
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(
        result=response,
        expected_result=expected_output,
    )
