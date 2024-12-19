from typing import Sequence

from ssrq_utils.lang.display import Lang
from ssrq_utils.uca import uca_complex_sort

from ssrq_editio.models.entities import Entity


def sort_entities_by_name(entities: Sequence[Entity], lang: Lang) -> Sequence[Entity]:
    """Sort a sequence of entities by name.

    The sorting key will be calculated based on the
    name of the entity.

    Args:
        entities (Sequence[Entity]): The entities to sort.
        lang (Lang): The language of the entities.

    Returns:
        Sequence[Entity]: The sorted entities.

    """
    return uca_complex_sort(entities, "get_name_by_lang", (lang,))
