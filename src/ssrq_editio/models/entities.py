from enum import Enum
from typing import Annotated, Sequence

from pydantic import BaseModel, BeforeValidator
from ssrq_utils.lang.display import Lang
from ssrq_utils.uca import uca_simple_sort

from ssrq_editio.services.utils import parse_as_list_or_return


class EntityTypes(Enum):
    FAMILIES = "families"
    KEYWORDS = "keywords"
    LEMMATA = "lemmata"
    ORGANIZATIONS = "organizations"
    PERSONS = "persons"
    PLACES = "places"


class Entity(BaseModel):
    id: str
    de_name: str | None
    fr_name: str | None
    it_name: str | None
    lt_name: str | None
    occurrences: Annotated[
        list[str] | None, BeforeValidator(lambda x: x.split(",") if isinstance(x, str) else x)
    ] = None

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

    def list_languages(self) -> list[str]:
        """Lists all languages for which a name is available.

        Returns:
            list[str]: List of languages for which a name is available.
        """
        return sorted(
            [key[:2] for key, value in self.model_dump().items() if key.endswith("_name") and value]
        )


class Entities(BaseModel):
    entities: Sequence[Entity]

    def get_by_id(self, entity_id: str) -> Entity | None:
        """Retrieve an entity by its ID.

        Args:
            entity_id (str): The

        Returns:
            Entity | None: The entity or None if not found.
        """
        return next((entity for entity in self.entities if entity.id == entity_id), None)


class Family(Entity):
    rm_name: str | None
    first_mention: str | None
    last_mention: str | None
    location: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ] = None


class Families(Entities):
    entities: Sequence[Family]


class Keyword(Entity):
    de_definition: str | None
    fr_definition: str | None
    it_definition: str | None

    def get_definition_by_lang(self, lang: Lang) -> str:
        definition = getattr(self, f"{lang.value}_definition", None)

        if definition:
            return definition

        return next(
            (
                definition
                for definition in (
                    self.de_definition,
                    self.fr_definition,
                    self.it_definition,
                )
                if definition
            ),
            "",
        )


class Keywords(Entities):
    entities: Sequence[Keyword]


class Lemma(Entity):
    rm_name: str | None
    de_definition: str | None
    fr_definition: str | None
    it_definition: str | None

    def get_name_by_lang(self, lang: Lang) -> str:
        name = getattr(self, f"{lang.value}_name", None)

        if name:
            return name

        return next(
            (
                name
                for name in (self.de_name, self.fr_name, self.it_name, self.lt_name, self.rm_name)
                if name
            ),
            "",
        )

    def get_definition_by_lang(self, lang: Lang) -> str:
        definition = getattr(self, f"{lang.value}_definition", None)

        if definition:
            return definition

        return next(
            (
                definition
                for definition in (
                    self.de_definition,
                    self.fr_definition,
                    self.it_definition,
                )
                if definition
            ),
            "",
        )


class Lemmata(Entities):
    entities: Sequence[Lemma]


class Organization(Entity):
    rm_name: str | None
    de_types: Annotated[list[str], BeforeValidator(parse_as_list_or_return)]
    fr_types: Annotated[list[str], BeforeValidator(parse_as_list_or_return)]
    location: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ] = None

    def get_types_by_lang(self, lang: Lang) -> list[str]:
        match lang:
            case Lang.FR:
                return self.fr_types
            case _:
                return self.de_types


class Organizations(Entities):
    entities: Sequence[Organization]


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
    location: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ] = None
    # ToDo occupations

    def get_name_by_lang(self, lang: Lang) -> str:
        name = getattr(self, f"{lang.value}_name", None)
        surname = getattr(self, f"{lang.value}_surname", None)

        if name and surname:
            return f"{surname}, {name}"

        return next(
            (
                f"{sname}, {nname}" if sname else nname
                for nname, sname in zip(
                    (self.de_name, self.fr_name, self.it_name, self.lt_name, self.rm_name),
                    (
                        self.de_surname,
                        self.fr_surname,
                        self.it_surname,
                        self.lt_surname,
                        self.rm_surname,
                    ),
                )
                if nname
            ),
            "",
        )


class Persons(Entities):
    entities: Sequence[Person]


class Place(Entity):
    cs_name: str | None
    nl_name: str | None
    pl_name: str | None
    rm_name: str | None
    de_place_types: Annotated[list[str], BeforeValidator(parse_as_list_or_return)]
    fr_place_types: Annotated[list[str], BeforeValidator(parse_as_list_or_return)]

    def get_name_by_lang(self, lang: Lang) -> str:
        name = getattr(self, f"{lang.value}_name", None)

        if name:
            return name

        return next(
            (
                name
                for name in (
                    self.de_name,
                    self.fr_name,
                    self.it_name,
                    self.lt_name,
                    self.rm_name,
                    self.nl_name,
                    self.pl_name,
                    self.cs_name,
                )
                if name
            ),
            "",
        )

    def get_place_type_by_lang(self, lang: Lang) -> str:
        match lang:
            case Lang.FR:
                return ", ".join(uca_simple_sort(self.fr_place_types))
            case _:
                return ", ".join(uca_simple_sort(self.de_place_types))


class Places(Entities):
    entities: Sequence[Place]
