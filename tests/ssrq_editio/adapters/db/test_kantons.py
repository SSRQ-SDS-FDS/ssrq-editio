import pytest

from ssrq_editio.adapters.db.kantons import initialize_kanton_data, list_kantons
from ssrq_editio.models.kantons import Kantons

FAKE_VOLUMES_DOCUMENTS = """
INSERT INTO volumes (id, sort_key, name, kanton_id, title, prefix) VALUES ("1", 1, "foo", 1, "bar", "SSRQ");
INSERT INTO volumes (id, sort_key, name, kanton_id, title, prefix) VALUES ("2", 2, "baz", 2, "foo", "SSRQ");

WITH RECURSIVE
    cnt(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM cnt WHERE x < 30)
INSERT INTO documents (
    uuid,
    idno,
    is_main,
    sort_key,
    de_orig_date,
    fr_orig_date,
    en_orig_date,
    it_orig_date,
    facs,
    printed_idno,
    volume_id,
    orig_place,
    type)
SELECT
    printf('uuid-%03d', x),
    printf('idno-%03d', x),
    1,
    x,
    '2023-01-01',
    '2023-01-01',
    '2023-01-01',
    '2023-01-01',
    0,
    printf('printed_idno-%03d', x),
    CASE WHEN x <= 15 THEN 1 ELSE 2 END,
    NULL,
    'transcript'
FROM cnt;
"""


@pytest.mark.anyio
async def test_initialize_kanton_data(db_setup):
    """Test if all kantons are inserted into the kantons table."""
    await initialize_kanton_data(db_setup)
    cursor = await db_setup.execute("SELECT * FROM kantons;")
    rows = await cursor.fetchall()
    assert len(rows) == 23  # type: ignore


@pytest.mark.anyio
async def test_list_kantons(db_kanton_data):
    """Test if all kantons are listed as Kantons-object(s)."""
    kantons = await list_kantons(db_kanton_data)
    assert isinstance(kantons, Kantons)
    assert len(kantons.kantons) == 23


@pytest.mark.anyio
async def test_list_kantons_with_fake_data(db_kanton_data):
    """Test if all kantons are listed as Kantons-object(s)."""
    async with db_kanton_data.cursor() as cursor:
        await cursor.executescript(FAKE_VOLUMES_DOCUMENTS)
    kantons = await list_kantons(db_kanton_data)
    assert isinstance(kantons, Kantons)
    assert len(kantons.kantons) == 23
    assert kantons.kantons[0].docs == 15
    assert kantons.kantons[1].docs == 15
