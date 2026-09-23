import pytest
from parsel import Selector
from ssrq_utils.lang.display import Lang


@pytest.mark.parametrize(
    ("page", "expected_document_start"),
    [
        ("44", "/api/v1/kantons/ZG/1_1.pdf#page=44"),
        (None, "/api/v1/kantons/ZG/1_1.pdf"),
    ],
)
def test_retro_viewer_uses_the_article_start_for_viewer_and_return_button(
    catalog, translator, page, expected_document_start
):
    html = catalog.render(
        "RetroViewer",
        endpoint="/api/v1/kantons/ZG/1_1.pdf",
        page=page,
        lang=Lang.DE,
        translator=translator,
    )
    selector = Selector(text=html)

    assert selector.css("iframe::attr(src)").get() == expected_document_start
    assert selector.css("iframe::attr(x-ref)").get() == "retroDocumentPdf"
    assert selector.css("button::attr(data-document-start)").get() == expected_document_start
    assert "x-on:click" in html
    assert "about:blank" not in html
    assert "ssrq-reset" in html
    assert "bg-ssrq-primary" in selector.css("button::attr(class)").get()
    assert selector.css("button::text").get().strip() == "Zum Beginn des Stücks"
