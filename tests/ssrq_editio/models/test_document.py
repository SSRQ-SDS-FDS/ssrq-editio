import pytest
from ssrq_utils.lang.display import Lang

from ssrq_editio.models.documents import DocumentTitle


@pytest.mark.parametrize(
    "lang, expected_title",
    [
        (Lang.DE, "German Title"),
        (Lang.FR, "French Title"),
        (Lang.EN, "German Title"),  # Fallback to German if no English title
    ],
)
def test_get_title_by_lang(lang, expected_title):
    document_title = DocumentTitle(de_title="German Title", fr_title="French Title")
    result = document_title.get_title_by_lang(lang)
    assert result == expected_title
