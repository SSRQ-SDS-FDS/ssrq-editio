from ssrq_utils.lang.display import Lang

from ssrq_editio.models.entities import Entity


def test_get_name_by_lang():
    entity = Entity(id="1", de_name="de", fr_name="fr", it_name="it", lt_name="lt")
    assert entity.get_name_by_lang(Lang.DE) == "de"
    assert entity.get_name_by_lang(Lang.FR) == "fr"
    assert entity.get_name_by_lang(Lang.IT) == "it"
    assert entity.get_name_by_lang(Lang.EN) == "de"
