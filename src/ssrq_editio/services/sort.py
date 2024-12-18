import threading
from typing import Sequence

from pyucollate.collator import BaseCollator, Collator_10_0_0  # type: ignore
from ssrq_utils.lang.display import Lang

from ssrq_editio.models.entities import Entity


class UnicodeCollator:
    """
    A singleton class to provide a Unicode collator.

    This class provides a Unicode collator for various sorting tasks.

    Attributes:
        collator (BaseCollator): The Unicode collator.
    """

    _instance = None
    _lock = threading.Lock()
    collator: BaseCollator

    def __new__(cls) -> "UnicodeCollator":  # noqa: D102
        if cls._instance is None:
            with cls._lock:
                cls._instance = super().__new__(cls)
                cls._instance._init_collator()
        return cls._instance

    def _init_collator(self) -> None:
        """Initialize the collator.

        Returns:
            None
        """
        self.collator = Collator_10_0_0()

    def sort_entities_by_name(self, entities: Sequence[Entity], lang: Lang) -> Sequence[Entity]:
        """Sort a sequence of entities by name.

        The sorting key will be calculated based on the
        name of the entity.

        Args:
            entities (Sequence[Entity]): The entities to sort.
            lang (Lang): The language of the entities.

        Returns:
            Sequence[Entity]: The sorted entities.
        """
        return sorted(
            entities, key=lambda entity: self.collator.sort_key(entity.get_name_by_lang(lang))
        )
