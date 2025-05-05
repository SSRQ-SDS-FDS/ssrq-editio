import aiosqlite
import pytest

from ssrq_editio.adapters.db.documents import initialize_document_data
from ssrq_editio.adapters.db.entities import (
    count_entities,
    delete_entities,
    list_entity_ids,
    search_families,
    search_keywords,
    search_lemmata,
    search_organizations,
    search_persons,
    search_places,
    store_entities,
)
from ssrq_editio.models.documents import Document, DocumentType
from ssrq_editio.models.entities import (
    Entities,
    EntityTypes,
    Families,
    Keywords,
    Lemmata,
    Organizations,
    Persons,
    Places,
)


@pytest.mark.anyio
async def test_store_entities(db_setup: aiosqlite.Connection, entities: tuple[Entities, ...]):
    """Smoke test to store entities in the database."""
    try:
        await store_entities(entities, db_setup)
    except Exception as error:
        pytest.fail(str(error))


@pytest.mark.anyio
async def test_delete_entities(db_setup: aiosqlite.Connection, entities: tuple[Entities, ...]):
    """Test if entities are deleted."""
    await delete_entities(connection=db_setup)
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.PLACES) == []
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.PERSONS) == []
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.LEMMATA) == []
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.KEYWORDS) == []
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.FAMILIES) == []


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "expected_results"),
    [
        (None, None),
        ("foo bar", None),
        ("loc000127", ["Zürichsee"]),
        (
            "Zürich",
            [
                "Zürich",
                "Zürich",
                "Zürich Rathaus",
                "Affoltern bei Zürich",
                "Barfüsserkirche Zürich",
                "Zürich Heiliggeistspital",
                "Zürich Spital",
            ],
        ),
        ("Affolt*", ["Affoltern bei Zürich", "Affoltern am Albis", "Affoltern"]),
    ],
)
async def test_search_places(
    db_setup, entities, search: str | None, expected_results: list[str] | None
):
    places = tuple([e for e in entities if isinstance(e, Places)])
    await store_entities(places, db_setup)
    result = await search_places(connection=db_setup, search=search)

    assert isinstance(result, Places)

    match search:
        case None:
            assert len(places[0].entities) == len(result.entities)
        case _ if expected_results is None:
            assert len(result.entities) == 0
        case _:
            assert len(result.entities) == len(expected_results)
            for i, expected_result in enumerate(expected_results):
                assert result.entities[i].de_name == expected_result
            # assert all(
            #     result.entities[i].de_name == expected_result
            #     for i, expected_result in enumerate(expected_results)
            # )


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "expected_results"),
    [
        (None, None),
        ("foo bar", None),
        ("org006252", ["St. Martin auf dem Zürichberg"]),
        (
            "Zürich",
            [
                "Zürich",
                "Zürich",
                "Zürich",
                "Zürich",
                "Zürich",
                "Zürich Grosser Rat",
                "Zürich Stadtgericht",
                "Zürich Heiliggeistspital",
                "Staatsarchiv Zürich",
            ],
        ),
        ("Züric", None),
        (
            "Züric*",
            [
                "Zürich",
                "Zürich",
                "Zürich",
                "Zürich",
                "Zürich",
                "Zürich Grosser Rat",
                "Zürich Stadtgericht",
                "Zürich Heiliggeistspital",
                "Staatsarchiv Zürich",
                "St. Martin auf dem Zürichberg",
                "Zürichbergamt",
            ],
        ),
        ("de_name:Zürichberg*", ["St. Martin auf dem Zürichberg", "Zürichbergamt"]),
    ],
)
async def test_search_organizations(
    db_setup, entities, search: str | None, expected_results: list[str] | None
):
    orgs = tuple([e for e in entities if isinstance(e, Organizations)])
    await store_entities(orgs, db_setup)
    result = await search_organizations(connection=db_setup, search=search)

    assert isinstance(result, Organizations)

    match search:
        case None:
            assert len(orgs[0].entities) == len(result.entities)
        case _ if expected_results is None:
            assert len(result.entities) == 0
        case _:
            assert len(result.entities) == len(expected_results)
            assert all(
                result.entities[i].de_name == expected_result
                for i, expected_result in enumerate(expected_results)
            )


@pytest.mark.anyio
async def test_search_places_with_occurrences(
    db_volume_data,
    entities,
):
    places = tuple([e for e in entities if isinstance(e, Places)])
    documents = (
        Document(
            uuid="d56f1ce8-cec9-49ed-b54b-09f397adc2d8",
            idno="SSRQ-SG-III_4-63-1",
            is_main=True,
            sort_key=63,
            de_orig_date="1473 April 26 a. S.",
            en_orig_date="1473 April 26 O.S.",
            fr_orig_date="1473 avril 26 a. s.",
            it_orig_date="1473 aprile 26 v. s.",
            facs=["OGA_Gams_Nr_5_r", "OGA_Gams_Nr_5_v"],
            printed_idno="SSRQ SG III/4 63",
            volume_id="SG_III_4",
            orig_place=["loc000211"],
            de_title="foo",
            fr_title=None,
            entities=["loc000127"],
            type=DocumentType.transcript,  # noqa: F821
        ),
    )
    await initialize_document_data(documents, db_volume_data)
    await store_entities(places, db_volume_data)

    result = await search_places(connection=db_volume_data, search="loc000127")

    assert isinstance(result, Places)
    assert len(result.entities) == 1
    assert result.entities[0].occurrences == [documents[0].uuid]


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "expected_results"),
    [
        (None, None),
        ("key000129", ["Wein"]),
        ("Wa", []),
        ("Weinb*", ["Weinberg"]),
    ],
)
async def test_search_keywords(
    db_setup, entities, search: str | None, expected_results: list[str] | None
):
    keywords = tuple([e for e in entities if isinstance(e, Keywords)])
    await store_entities(keywords, db_setup)
    result = await search_keywords(connection=db_setup, search=search)

    assert isinstance(result, Keywords)

    match search:
        case None:
            assert len(keywords[0].entities) == len(result.entities)
        case _ if expected_results is None:
            assert len(result.entities) == 0
        case _:
            assert len(result.entities) == len(expected_results)
            assert all(
                result.entities[i].de_name == expected_result
                for i, expected_result in enumerate(expected_results)
            )


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "expected_results"),
    [
        (None, None),
        ("lem008330", ["roter wein"]),
        (
            "krieg",
            [
                "krieg",
                "Burgundischer krieg",
                "krieg",
                "billiger krieg",
                "St. Galler krieg",
                "krieg",
                "in (den) krieg laufen",
            ],
        ),
        ("burgundisch*", ["Burgundischer krieg"]),
    ],
)
async def test_search_lemmata(
    db_setup, entities, search: str | None, expected_results: list[str] | None
):
    lemmata = tuple([e for e in entities if isinstance(e, Lemmata)])
    await store_entities(lemmata, db_setup)
    result = await search_lemmata(connection=db_setup, search=search)

    assert isinstance(result, Lemmata)

    match search:
        case None:
            assert len(lemmata[0].entities) == len(result.entities)
        case _ if expected_results is None:
            assert len(result.entities) == 0
        case _:
            assert len(result.entities) == len(expected_results)
            assert all(
                result.entities[i].de_name == expected_result
                for i, expected_result in enumerate(expected_results)
            )


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "expected_results"),
    [
        (None, None),
        ("foo bar", None),
        ("per007472", ["Peter"]),
        ("Meier", ["Heinrich"]),
        ("Meie", None),
        ("Meie*", ["Heinrich"]),
    ],
)
async def test_search_persons(
    db_setup, entities, search: str | None, expected_results: list[str] | None
):
    persons = tuple([e for e in entities if isinstance(e, Persons)])
    await store_entities(persons, db_setup)
    result = await search_persons(connection=db_setup, search=search)

    assert isinstance(result, Persons)

    match search:
        case None:
            assert len(persons[0].entities) == len(result.entities)
        case _ if expected_results is None:
            assert len(result.entities) == 0
        case _:
            assert len(result.entities) == len(expected_results)
            assert all(
                result.entities[i].de_name == expected_result
                for i, expected_result in enumerate(expected_results)
            )


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "expected_results"),
    [
        (None, None),
        ("foo bar", None),
        ("org000195", ["Vasön, von"]),
        ("Meier", ["Altstätten, von", "Meier", "Meier"]),
        ("Mei", None),
        ("Meie*", ["Altstätten, von", "Meier", "Meienberg", "Meier"]),
    ],
)
async def test_search_families(
    db_setup, entities, search: str | None, expected_results: list[str] | None
):
    families = tuple([e for e in entities if isinstance(e, Families)])
    await store_entities(families, db_setup)
    result = await search_families(connection=db_setup, search=search)
    assert isinstance(result, Families)

    match search:
        case None:
            assert len(families[0].entities) == len(result.entities)
        case _ if expected_results is None:
            assert len(result.entities) == 0
        case _:
            assert len(result.entities) == len(expected_results)
            assert all(
                result.entities[i].de_name == expected_result
                for i, expected_result in enumerate(expected_results)
            )


@pytest.mark.anyio
async def test_count_entities(
    db_setup,
    entities,
):
    places = tuple(e for e in entities if isinstance(e, Places))
    await store_entities(places, db_setup)
    result = await count_entities(connection=db_setup, table=EntityTypes.PLACES)
    assert result == len(places[0].entities)


@pytest.mark.anyio
async def test_list_entity_ids(
    db_setup,
    entities,
):
    places = tuple(e for e in entities if isinstance(e, Places))
    await store_entities(places, db_setup)
    result = await list_entity_ids(connection=db_setup, table=EntityTypes.PLACES)
    assert len(result) == len(places[0].entities)
    assert all(e_id.id in result for e_id in places[0].entities)


@pytest.mark.anyio
async def test_list_entity_ids_with_invalid_table_name(
    db_setup,
    entities,
):
    places = tuple(e for e in entities if isinstance(e, Places))
    await store_entities(places, db_setup)
    with pytest.raises(ValueError):
        await list_entity_ids(connection=db_setup, table="place")  # type: ignore
