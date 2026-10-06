import pytest
from parsel import Selector
from ssrq_utils.lang.display import Lang


@pytest.mark.parametrize(
    "names, expected",
    [
        ([], None),
        (["Eva Editor"], "von Eva Editor"),
        (["Zoe Editor", "Anna Editor"], "von Zoe Editor und Anna Editor"),
        (["Zoe Editor", "Anna Editor", "Max Editor"], "von Zoe Editor, Anna Editor und Max Editor"),
    ],
)
def test_editor_list_preserves_order_and_handles_empty_lists(catalog, translator, names, expected):
    html = catalog.render("EditorList", editors=names, lang=Lang.DE, translator=translator)
    paragraph = Selector(text=html).css("p")
    if expected is None:
        assert not paragraph
    else:
        assert " ".join(paragraph.xpath("string(.)").get().split()) == expected
