from uuid import uuid4

import pytest

from ssrq_editio.adapters.db.documents import initialize_document_data
from ssrq_editio.models.documents import Document


@pytest.fixture
def documents():
    return tuple(
        Document(
            uuid=str(uuid4()),
            idno=f"SSRQ-SG-III_4-{d}-1",
            is_main=True,
            sort_key=d,
            de_orig_date="foo",
            en_orig_date="foo",
            fr_orig_date="foo",
            it_orig_date="foo",
            facs=["bar", "baz"] if d % 2 == 0 else None,
            printed_idno=f"SSRQ SG III/4 {d}",
            volume_id="SG_III_4",
            orig_place=["loc000001"],
            de_title="<h3>foo</h3>",
            fr_title=None,
        )
        for d in range(1, 150)
    )


@pytest.mark.anyio
async def test_initialize_document_data(db_volume_data, documents):
    # Smoke test, if query is successful
    await initialize_document_data(documents=documents, connection=db_volume_data)
