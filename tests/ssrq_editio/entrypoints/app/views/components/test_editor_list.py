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


@pytest.mark.parametrize(
    "names, expected",
    [
        ([], None),
        (["Anna Dupont"], "avec la collaboration d’Anna Dupont"),
        (["Émilie Dupont"], "avec la collaboration d’Émilie Dupont"),
        (["Bernard Dupont"], "avec la collaboration de Bernard Dupont"),
        (["A. Dupont"], "avec la collaboration de A. Dupont"),
        (["Hans Müller"], "avec la collaboration de Hans Müller"),
        (["Anna Dupont", "Zoe Martin"], "avec la collaboration d’Anna Dupont et Zoe Martin"),
        (
            ["Anna Dupont", "Max Martin", "Zoe Martin"],
            "avec la collaboration d’Anna Dupont, Max Martin et Zoe Martin",
        ),
        (
            ["Bernard Dupont", "Anna Martin"],
            "avec la collaboration de Bernard Dupont et Anna Martin",
        ),
    ],
)
def test_editor_list_french_collaboration(catalog, translator, names, expected):
    html = catalog.render(
        "EditorList",
        editors=names,
        lang=Lang.FR,
        translator=translator,
        prefix_key="with_collaboration_of",
    )
    paragraph = Selector(text=html).css("p")
    if expected is None:
        assert not paragraph
    else:
        assert " ".join(paragraph.xpath("string(.)").get().split()) == expected


def test_editor_list_french_editors_keep_ordinary_prefix(catalog, translator):
    html = catalog.render(
        "EditorList", editors=["Anna Dupont"], lang=Lang.FR, translator=translator
    )
    assert " ".join(Selector(text=html).xpath("string(//p)").get().split()) == "par Anna Dupont"


def test_editor_list_escapes_names(catalog, translator):
    catalog.jinja_env.autoescape = True
    html = catalog.render(
        "EditorList",
        editors=["Anna <script>alert(1)</script>"],
        lang=Lang.FR,
        translator=translator,
        prefix_key="with_collaboration_of",
    )
    assert not Selector(text=html).css("script")
    assert "d’Anna &lt;script&gt;" in html
