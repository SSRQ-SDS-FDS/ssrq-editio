from random import randint
from uuid import uuid4

import pytest

from ssrq_editio.adapters.db.documents import initialize_document_data
from ssrq_editio.adapters.db.volumes import (
    initialize_volume_data,
    initialize_volume_with_editors,
    list_volumes_with_editors,
    retrieve_volume_metadata,
)
from ssrq_editio.models.documents import Document, DocumentType
from ssrq_editio.models.volumes import Volume, VolumeMeta


@pytest.fixture
def documents():
    return tuple(
        Document(  # noqa: F821
            uuid=str(uuid4()),
            idno=f"SSRQ-SG-III_4-{d}-1",
            is_main=True,
            sort_key=d,
            de_orig_date="foo",
            en_orig_date="foo",
            fr_orig_date="foo",
            it_orig_date="foo",
            facs=["bar", "baz"] if d % 2 == 0 else None,
            printed_idno=f"foo {d}",
            volume_id="foo",
            orig_place=["loc000001"],
            de_title="<h3>foo</h3>",
            fr_title=None,
            type=DocumentType.transcript,
            start_year_of_creation=randint(900, 1780),
            end_year_of_creation=randint(900, 1780) if d % 2 == 0 else None,
        )
        for d in range(1, 150)
    )


TEST_VOLUME = Volume(
    key="foo",
    sort_key=1,
    name="foo",
    kanton="ZH",
    title="foo",
    pdf="foo.pdf",
    literature="foo",
    editors=["foo Editor"],
    prefix="SSRQ",
)


@pytest.mark.anyio
async def test_initialize_volume_data(db_kanton_data):
    """Test if all volumes are inserted into the volumes table."""
    await initialize_volume_data(db_kanton_data, TEST_VOLUME)
    volumes = await db_kanton_data.execute("SELECT * FROM volumes;")
    rows = await volumes.fetchall()
    assert len(rows) == 1


@pytest.mark.anyio
async def test_list_volumes_with_editors(db_kanton_data):
    """Test if all inserted volumes can be listed with their editors."""
    test_volumes = [
        Volume(
            key=f"foo{i}",
            sort_key=i,
            name=f"foo_{1}",
            kanton="ZH",
            title="foo",
            pdf="foo.pdf",
            literature="foo",
            editors=["foo Editor", f"{i}"],
            prefix="SSRQ",
        )
        for i in range(3)
    ]
    for volume in test_volumes:
        await initialize_volume_with_editors(db_kanton_data, volume)
    volumes = await list_volumes_with_editors(db_kanton_data, "ZH")
    assert volumes is not None
    assert len(volumes) == len(test_volumes)
    for i, volume in enumerate(volumes):
        assert isinstance(volume, Volume)
        assert volume.key == test_volumes[i].key
        assert volume.sort_key == test_volumes[i].sort_key
        assert volume.name == test_volumes[i].name
        assert volume.kanton == test_volumes[i].kanton
        assert volume.title == test_volumes[i].title
        assert volume.pdf == test_volumes[i].pdf
        assert volume.literature == test_volumes[i].literature
        assert all(editor in test_volumes[i].editors for editor in volume.editors)


@pytest.mark.anyio
async def test_list_volumes_with_editors_for_unknown_kanton(db_kanton_data):
    """Test if None is returned for unknown kanton."""
    await initialize_volume_with_editors(db_kanton_data, TEST_VOLUME)
    volumes = await list_volumes_with_editors(db_kanton_data, "FOO")
    assert volumes is None


@pytest.mark.anyio
async def test_retrieve_volume_meta(db_kanton_data, documents):
    await initialize_volume_with_editors(db_kanton_data, TEST_VOLUME)
    await initialize_document_data(documents, db_kanton_data)
    result = await retrieve_volume_metadata(db_kanton_data, "foo")
    assert result is not None
    assert isinstance(result, VolumeMeta)
    assert (
        min(d.start_year_of_creation for d in documents if d.start_year_of_creation)
        == result.first_year
    )
    assert (
        max(d.end_year_of_creation for d in documents if d.end_year_of_creation) == result.last_year
    )
