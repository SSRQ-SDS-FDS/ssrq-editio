from ssrq_editio.models.lang import Lang
import pytest


@pytest.mark.parametrize(
    ("lang, expected"),
    [
        ("deu", Lang.DE),
        ("eng", Lang.EN),
        ("ita", Lang.IT),
        ("fra", Lang.FR),
        ("roh", Lang.DE),
    ],
)
def test_lang_from_string(lang, expected):
    assert Lang.from_string(lang) == expected
