import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
)

from cli.config import PROJECT_ROOT, EXIST_APP_DIR
import json
from parsel import Selector

from httpx import codes


@pytest.mark.asyncio_cooperative
async def test_kantons_list_returns_one_row_per_kanton(execute_xquery: xquery_tester):
    xquery = build_query(
        modules=[xquery_modules["kantons"], xquery_modules["views"]],
        query_body="""kantons:list(<div/>, map{})""",
    )
    response = await execute_xquery(xquery)

    assert response.status_code == codes.OK

    with open(PROJECT_ROOT / EXIST_APP_DIR / "resources/json/cantons.json") as kantons_file:
        kantons = json.load(kantons_file)

    assert len(
        Selector(response.text).xpath("//div[@class = 'kanton-card_content-heading']/h4")
    ) == len(kantons.keys())
