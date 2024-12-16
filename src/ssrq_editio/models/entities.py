from typing import Sequence

from pydantic import BaseModel
from ssrq_utils.lang.display import Lang


class Entity(BaseModel):
    id: str
    de_name: str | None
    fr_name: str | None
    it_name: str | None
    lt_name: str | None
    occurrences: list[str] | None = None

    def get_name_by_lang(self, lang: Lang) -> str:
        """Retrieve the name of the entity in the specified language.

        If the name is not available in the specified language, the function
        will return the name in the next available language. If no name is
        available, an empty string is returned.

        Args:
            lang (Lang): Language enum object.

        Returns:
            str: Name of the entity in the specified language.
        """
        name = getattr(self, f"{lang.value}_name", None)

        if name:
            return name

        return next(
            (name for name in (self.de_name, self.fr_name, self.it_name, self.lt_name) if name), ""
        )


class Entities(BaseModel):
    entities: Sequence[Entity]


class Keyword(Entity):
    pass


class Keywords(Entities):
    entities: Sequence[Keyword]


class Lemma(Entity):
    rm_name: str | None


class Lemmata(Entities):
    entities: Sequence[Lemma]


class Person(Entity):
    rm_name: str | None
    de_surname: str | None
    fr_surname: str | None
    it_surname: str | None
    lt_surname: str | None
    rm_surname: str | None
    sex: str
    first_mention: str | None
    last_mention: str | None
    birth: str | None
    death: str | None
    # ToDo occupations / locations !


class Persons(Entities):
    entities: Sequence[Person]


class Place(Entity):
    cs_name: str | None
    nl_name: str | None
    pl_name: str | None
    rm_name: str | None


class Places(Entities):
    entities: Sequence[Place]
