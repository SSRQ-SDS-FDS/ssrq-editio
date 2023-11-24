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
