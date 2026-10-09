import pytest
from fastapi import Request
from parsel import Selector
from ssrq_utils.lang.display import Lang

from ssrq_editio.models.documents import DocumentDescription, DocumentDescriptionHeading


@pytest.mark.parametrize("witness_number", [None, "", "I"])
def test_document_description_only_prefixes_existing_witness_numbers(
    catalog, translator, witness_number
):
    catalog.jinja_env.autoescape = True
    descriptions = [
        DocumentDescription(heading=DocumentDescriptionHeading(witnessNumber=witness_number)),
        DocumentDescription(heading=DocumentDescriptionHeading(witnessNumber="II")),
    ]
    html = catalog.render(
        "DocumentDescription",
        descriptions=descriptions,
        lang=Lang.DE,
        request=Request({"type": "http"}),
        translator=translator,
    )
    headings = Selector(text=html).css("h3")
    first_heading = headings[0].xpath("string(.)").get()
    assert " ".join(first_heading.split()) == (
        "I Editionsvorlage" if witness_number else "Editionsvorlage"
    )
    assert ("\u00a0" in first_heading) is bool(witness_number)
    assert " ".join(headings[1].xpath("string(.)").get().split()) == "II Weitere Überlieferung"
    assert "&amp;nbsp;" not in html
