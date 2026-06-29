from parsel import Selector


def test_document_image_renders_relative_graphic_path(catalog):
    html = catalog.render("DocumentImage", src="WB_HB.svg", type="Stammbaum")
    doc = Selector(text=html)

    assert doc.css('img[alt="Stammbaum"]::attr(src)').get() == "./graphic/WB_HB.svg"
