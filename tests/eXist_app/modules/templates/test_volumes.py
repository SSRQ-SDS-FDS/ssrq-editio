import pytest
from httpx import codes
from parsel import Selector

from tests.eXist_app.conftest import (
    assert_xquery_result,
    build_query,
    xquery_modules,
    xquery_tester,
)


@pytest.mark.asyncio_cooperative
async def test_volumes_list_for_sg(execute_xquery: xquery_tester):
    "Expect one volume (SG III 4) for kanton SG"
    xquery = build_query(
        modules=[xquery_modules["views"], xquery_modules["volumes"]],
        query_body="""let $config := views:get-template-config(map{"parameters": map{"kanton": "SG"}})
        let $result := volumes:list(<div/>, $config, 'SG')?volumes
        return
            count($result) eq 1 and
            (
                every $vol in $result satisfies
                $vol instance of array(*) and
                array:get($vol, 1) instance of element(volume) and
                array:get($vol, 2) instance of element(tei:TEI)
            )
        """,  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)


@pytest.mark.asyncio_cooperative
async def test_render_volume_title(execute_xquery: xquery_tester):
    "Test if the rendered volume title for SG III 4 is rendered as expected"
    xquery = build_query(
        modules=[xquery_modules["views"], xquery_modules["volumes"]],
        query_body="""let $config := views:get-template-config(map{"parameters": map{"kanton": "SG"}})
        let $model := volumes:list(<div/>, $config, 'SG')
        for $volume in $model?volumes
        let $mod-model := map:put($model, 'volume', $volume)
        return
            volumes:render-volume-title(<div/>, $mod-model)
        """,  # noqa
    )
    response = await execute_xquery(xquery)

    expected_title = """XIV. Abteilung: Die Rechtsquellen des Kantons St. Gallen, Dritter Teil"""  # noqa

    assert response.status_code == codes.OK

    response_selector = Selector(response.text)

    title = response_selector.xpath("//h3/text()").get()

    assert title is not None
    assert expected_title in title

    editor = response_selector.xpath("//p/span/text()").get()

    assert editor is not None
    assert "Sibylle Malamud" in editor
