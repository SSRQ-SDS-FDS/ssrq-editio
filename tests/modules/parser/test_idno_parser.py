import pytest
from parsel import Selector

from tests.conftest import build_query, xquery_modules, xquery_tester


@pytest.mark.asyncio
async def test_simple_idno_parsing(execute_query: xquery_tester):
    """Test the parsing of idnos."""
    xquery = build_query(
        modules=[xquery_modules["idno-parser"]],
        query_body="idno-parser:parse-regular('SSRQ-SG-III_4-58-1')",
    )
    response = await execute_query(xquery)

    assert response.status_code == 200

    selector = Selector(response.text, type="xml")
    assert selector.xpath("doc/text()").get() == "58"
    assert selector.xpath("num/text()").get() == "1"


@pytest.mark.asyncio
async def test_idno_parsing_with_case(execute_query: xquery_tester):
    """Test the parsing of idnos."""
    xquery = build_query(
        modules=[xquery_modules["idno-parser"]],
        query_body="idno-parser:parse-regular('SSRQ-FR-I_2_8-87.2-1')",
    )
    response = await execute_query(xquery)

    assert response.status_code == 200

    selector = Selector(response.text, type="xml")
    assert selector.xpath("volume/text()").get() == "I_2_8"
    assert selector.xpath("case/text()").get() == "87"
    assert selector.xpath("doc/text()").get() == "2"


@pytest.mark.asyncio
async def test_idno_parsing_with_case_and_opening(execute_query: xquery_tester):
    """Test the parsing of idnos."""
    xquery = build_query(
        modules=[xquery_modules["idno-parser"]],
        query_body="idno-parser:parse-regular('SDS-NE-4-1.A.1-1')",
    )
    response = await execute_query(xquery)

    assert response.status_code == 200

    selector = Selector(response.text, type="xml")
    assert selector.xpath("volume/text()").get() == "4"
    assert selector.xpath("case/text()").get() == "1"
    assert selector.xpath("opening/text()").get() == "A"
