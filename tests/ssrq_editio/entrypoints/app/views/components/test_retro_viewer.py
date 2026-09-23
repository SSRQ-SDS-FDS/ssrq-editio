import pytest
from parsel import Selector


@pytest.mark.parametrize(
    ("page", "expected_src"),
    [
        ("44", "/api/v1/kantons/ZG/1_1.pdf#page=44"),
        (None, "/api/v1/kantons/ZG/1_1.pdf"),
    ],
)
def test_retro_viewer_uses_the_optional_pdf_page(catalog, page, expected_src):
    html = catalog.render("RetroViewer", endpoint="/api/v1/kantons/ZG/1_1.pdf", page=page)

    assert Selector(text=html).css("iframe::attr(src)").get() == expected_src
