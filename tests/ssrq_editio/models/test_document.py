import pytest
from ssrq_utils.lang.display import Lang

from ssrq_editio.models.documents import Document, DocumentTitle, DocumentType


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


def test_document_keywords_are_optional_and_accept_serialized_lists():
    document = Document(
        uuid="document-uuid",
        idno="SSRQ-SG-III_4-1-1",
        is_main=True,
        sort_key="0001",
        de_orig_date="",
        en_orig_date="",
        fr_orig_date="",
        it_orig_date="",
        facs=None,
        printed_idno="SSRQ SG III/4 1",
        volume_id="SG_III_4",
        type=DocumentType.transcript,
        keywords='["key000001", "key000002"]',
    )

    assert document.keywords == ["key000001", "key000002"]
    assert Document.model_validate(document.model_dump()).keywords == document.keywords


def test_document_keywords_default_to_none():
    document = Document(
        uuid="document-uuid",
        idno="SSRQ-SG-III_4-1-1",
        is_main=True,
        sort_key="0001",
        de_orig_date="",
        en_orig_date="",
        fr_orig_date="",
        it_orig_date="",
        facs=None,
        printed_idno="SSRQ SG III/4 1",
        volume_id="SG_III_4",
        type=DocumentType.transcript,
    )

    assert document.keywords is None
