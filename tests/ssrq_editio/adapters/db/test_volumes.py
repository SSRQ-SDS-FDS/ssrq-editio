import pytest

from ssrq_editio.adapters.db.volumes import (
    initialize_volume_data,
    initialize_volume_with_editors,
    list_volumes_with_editors,
)
from ssrq_editio.models.volumes import Volume

TEST_VOLUME = Volume(
    key="foo",
    name="foo",
    kanton="ZH",
    title="foo",
    pdf="foo.pdf",
    literature="foo",
    editors=["foo Editor"],
)


@pytest.mark.asyncio_cooperative
async def test_initialize_volume_data(db_kanton_data):
    """Test if all volumes are inserted into the volumes table."""
    await initialize_volume_data(db_kanton_data, TEST_VOLUME)
    volumes = await db_kanton_data.execute("SELECT * FROM volumes;")
    rows = await volumes.fetchall()
    assert len(rows) == 1


@pytest.mark.asyncio_cooperative
async def test_list_volumes_with_editors(db_kanton_data):
    """Test if all inserted volumes can be listed with their editors."""
    await initialize_volume_with_editors(db_kanton_data, TEST_VOLUME)
    volumes = await list_volumes_with_editors(db_kanton_data, "ZH")
    assert volumes is not None
    assert len(volumes) == 1
    assert volumes[0].editors == ["foo Editor"]
    assert isinstance(volumes[0], Volume)


@pytest.mark.asyncio_cooperative
async def test_list_volumes_with_editors_for_unknown_kanton(db_kanton_data):
    """Test if None is returned for unknown kanton."""
    await initialize_volume_with_editors(db_kanton_data, TEST_VOLUME)
    volumes = await list_volumes_with_editors(db_kanton_data, "FOO")
    assert volumes is None
