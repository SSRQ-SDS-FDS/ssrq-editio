from ssrq_utils.lang.display import Lang

from ssrq_editio.models.entities import Entity, Person


def test_get_name_by_lang():
    entity = Entity(id="1", de_name="de", fr_name="fr", it_name="it", lt_name="lt")
    assert entity.get_name_by_lang(Lang.DE) == "de"
    assert entity.get_name_by_lang(Lang.FR) == "fr"
    assert entity.get_name_by_lang(Lang.IT) == "it"
    assert entity.get_name_by_lang(Lang.EN) == "de"


def test_person_get_name_by_lang_name_order():
    person = Person(
        id="1",
        de_name="Anna",
        de_surname="Muster",
        fr_name="Anne",
        fr_surname="Dupont",
        it_name="Anna",
        it_surname="Rossi",
        lt_name=None,
        lt_surname=None,
        rm_name=None,
        rm_surname=None,
        sex="",
        first_mention=None,
        last_mention=None,
        birth=None,
        death=None,
    )

    assert person.get_name_by_lang(Lang.DE) == "Muster, Anna"
    assert person.get_name_by_lang(Lang.DE, surname_first=True) == "Muster, Anna"
    assert person.get_name_by_lang(Lang.DE, surname_first=False) == "Anna Muster"
    assert person.get_name_by_lang(Lang.FR, surname_first=False) == "Anne Dupont"
    assert person.get_name_by_lang(Lang.IT, surname_first=False) == "Anna Rossi"

    # test fallback
    assert person.get_name_by_lang(Lang.EN, surname_first=True) == "Muster, Anna"
    assert person.get_name_by_lang(Lang.EN, surname_first=False) == "Anna Muster"
