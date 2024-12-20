from asyncio import TaskGroup
from os import getenv
from typing import Any, Callable, Coroutine, cast

from httpx import AsyncClient
from httpx._status_codes import codes
from parsel import Selector

from ssrq_editio.models.entities import (
    Entities,
    Families,
    Family,
    Keyword,
    Keywords,
    Lemma,
    Lemmata,
    Organization,
    Organizations,
    Person,
    Persons,
    Place,
    Places,
)
from ssrq_editio.services.utils import normalize

PLACES_API = getenv("PLACES_API", "https://loci.ssrq-sds-fds.ch/views/places4index-v3.xq")
KEYWORDS_API = getenv("KEYWORDS_API", "https://termini.ssrq-sds-fds.ch/views/keywords4index-v3.xq")
LEMMATA_API = getenv("LEMMATA_API", "https://termini.ssrq-sds-fds.ch/views/lemmas4index-v3.xq")
PERSONS_API = getenv("PERSONS_API", "https://api.personae.ssrq-sds-fds.ch/?persons_for_index")
FAMILIES_API = getenv("FAMILIES_API", "https://api.personae.ssrq-sds-fds.ch/?families_for_index")
ORGANIZATION_API = getenv(
    "ORG_API", "https://api.personae.ssrq-sds-fds.ch/?organisations_for_index"
)


class APIFetchError(Exception):
    pass


async def get_places(client: AsyncClient, url: str) -> Places:
    """Adapter, which supports fetching places from the XRX index v3-API.

    Args:
        client: An instance of `httpx.AsyncClient`.
        url: The URL of the API endpoint.

    Returns:
        A `Places` object containing the fetched places.
    """
    response = await client.get(url, follow_redirects=True)

    if response.status_code != codes.OK:
        raise APIFetchError(f"Failed to fetch places from {url}")

    tree = Selector(response.text, type="xml")

    return Places(
        entities=[
            Place(
                id=cast(str, place.xpath("./@id").get()),
                cs_name=place.xpath("./stdName[@lang='ces']/text()").get(),
                nl_name=place.xpath("./stdName[@lang='nld']/text()").get(),
                pl_name=place.xpath("./stdName[@lang='pol']/text()").get(),
                rm_name=place.xpath("./stdName[@lang='roh']/text()").get(),
                de_name=place.xpath("./stdName[@lang='deu']/text()").get(),
                fr_name=place.xpath("./stdName[@lang='fra']/text()").get(),
                it_name=place.xpath("./stdName[@lang='ita']/text()").get(),
                lt_name=place.xpath("./stdName[@lang='lat']/text()").get(),
                de_place_types=[
                    pt.get() for pt in place.xpath("./type/definition[@lang='deu']/text()")
                ],
                fr_place_types=[
                    pt.get() for pt in place.xpath("./type/definition[@lang='fra']/text()")
                ],
                occurrences=None,
            )
            for place in tree.xpath(".//place")
        ]
    )


async def get_keywords(client: AsyncClient, url: str) -> Keywords:
    """Adapter, which supports fetching keywords from the XRX index v3-API.

    Args:
        client: An instance of `httpx.AsyncClient`.
        url: The URL of the API endpoint.

    Returns:
        A `Keywords` object containing the fetched places.
    """
    response = await client.get(url, follow_redirects=True)

    if response.status_code != codes.OK:
        raise APIFetchError(f"Failed to fetch keywords from {url}")

    tree = Selector(response.text, type="xml")

    return Keywords(
        entities=[
            Keyword(
                id=cast(str, keyword.xpath("./@id").get()),
                occurrences=None,
                de_name=normalize(keyword.xpath("./name[@lang='deu']/text()").get()),
                fr_name=normalize(keyword.xpath("./name[@lang='fra']/text()").get()),
                it_name=normalize(keyword.xpath("./name[@lang='ita']/text()").get()),
                de_definition=normalize(keyword.xpath("./definition[@lang='deu']/text()").get()),
                fr_definition=normalize(keyword.xpath("./definition[@lang='fra']/text()").get()),
                it_definition=normalize(keyword.xpath("./definition[@lang='ita']/text()").get()),
                lt_name=None,
            )
            for keyword in tree.xpath(".//keyword")
        ]
    )


async def get_lemmata(client: AsyncClient, url: str) -> Lemmata:
    """Adapter, which supports fetching lemmata from the XRX index v3-API.

    Args:
        client: An instance of `httpx.AsyncClient`.
        url: The URL of the API endpoint.

    Returns:
        A `Lemmata` object containing the fetched places.
    """
    response = await client.get(url, follow_redirects=True)

    if response.status_code != codes.OK:
        raise APIFetchError(f"Failed to fetch lemmata from {url}")

    tree = Selector(response.text, type="xml")

    return Lemmata(
        entities=[
            Lemma(
                id=cast(str, keyword.xpath("./@id").get()),
                occurrences=None,
                de_name=normalize(keyword.xpath("./stdName[@lang='deu']/text()").get()),
                fr_name=normalize(keyword.xpath("./stdName[@lang='fra']/text()").get()),
                it_name=normalize(keyword.xpath("./stdName[@lang='ita']/text()").get()),
                lt_name=normalize(keyword.xpath("./stdName[@lang='lat']/text()").get()),
                rm_name=normalize(keyword.xpath("./stdName[@lang='roh']/text()").get()),
                de_definition=normalize(keyword.xpath("./definition[@lang='deu']/text()").get()),
                fr_definition=normalize(keyword.xpath("./definition[@lang='fra']/text()").get()),
                it_definition=normalize(keyword.xpath("./definition[@lang='ita']/text()").get()),
            )
            for keyword in tree.xpath(".//lemma")
        ]
    )


async def get_families(client: AsyncClient, url: str) -> Families:
    """Adapter, which supports fetching families from the PersonsDB-index-API.

    Args:
        client: An instance of `httpx.AsyncClient`.
        url: The URL of the API endpoint.

    Returns:
        A `Families` object containing the fetched places.
    """
    response = await client.get(url, follow_redirects=True)

    if response.status_code != codes.OK:
        raise APIFetchError(f"Failed to fetch families from {url}")

    tree = Selector(response.text, type="xml")

    return Families(
        entities=[
            Family(
                id=cast(str, keyword.xpath("./@id").get()),
                occurrences=None,
                de_name=keyword.xpath("./standard_name[@lang='deu']/text()").get(),
                fr_name=keyword.xpath("./standard_name[@lang='fra']/text()").get(),
                it_name=keyword.xpath("./standard_name[@lang='ita']/text()").get(),
                lt_name=keyword.xpath("./standard_name[@lang='lat']/text()").get(),
                rm_name=keyword.xpath("./standard_name[@lang='roh']/text()").get(),
            )
            for keyword in tree.xpath(".//family")
        ]
    )


async def get_orgs(client: AsyncClient, url: str) -> Organizations:
    """Adapter, which supports fetching orgs from the PersonsDB-index-API.

    Args:
        client: An instance of `httpx.AsyncClient`.
        url: The URL of the API endpoint.

    Returns:
        A `Organizations` object containing the fetched places.
    """
    response = await client.get(url, follow_redirects=True)

    if response.status_code != codes.OK:
        raise APIFetchError(f"Failed to fetch orgs from {url}")

    tree = Selector(response.text, type="xml")

    return Organizations(
        entities=[
            Organization(
                id=cast(str, keyword.xpath("./@id").get()),
                occurrences=None,
                de_name=keyword.xpath("./standard_name[@lang='deu']/text()").get(),
                fr_name=keyword.xpath("./standard_name[@lang='fra']/text()").get(),
                it_name=keyword.xpath("./standard_name[@lang='ita']/text()").get(),
                lt_name=keyword.xpath("./standard_name[@lang='lat']/text()").get(),
                rm_name=keyword.xpath("./standard_name[@lang='roh']/text()").get(),
                de_type=cast(str, keyword.xpath(".//definition[@lang='deu']/text()").get()),
                fr_type=cast(str, keyword.xpath(".//definition[@lang='deu']/text()").get()),
            )
            for keyword in tree.xpath(".//organisation")
        ]
    )


async def get_persons(client: AsyncClient, url: str) -> Persons:
    """Adapter, which supports fetching persons from the PersonsDB-index-API.

    Args:
        client: An instance of `httpx.AsyncClient`.
        url: The URL of the API endpoint.

    Returns:
        A `Persons` object containing the fetched places.
    """

    def _get_forename(name: str | None) -> str | None:
        if name is None:
            return None

        return name.split(", ")[-1].strip()

    def _get_surname(name: str | None) -> str | None:
        if name is None:
            return None

        return ", ".join(name.split(", ")[:-1]).strip()

    response = await client.get(url, follow_redirects=True)

    if response.status_code != codes.OK:
        raise APIFetchError(f"Failed to fetch persons from {url}")
    tree = Selector(response.text, type="xml")

    persons = []

    for person in tree.xpath(".//person"):
        standard_names = {
            lang: person.xpath(f"./standard_name[@lang='{lang}']/text()").get()
            for lang in ["deu", "fra", "ita", "lat", "roh"]
        }
        persons.append(
            Person(
                id=cast(str, person.xpath("./@id").get()),
                occurrences=None,
                de_name=_get_forename(standard_names["deu"]),
                fr_name=_get_forename(standard_names["fra"]),
                it_name=_get_forename(standard_names["ita"]),
                lt_name=_get_forename(standard_names["lat"]),
                rm_name=_get_forename(standard_names["roh"]),
                de_surname=_get_surname(standard_names["deu"]),
                fr_surname=_get_surname(standard_names["fra"]),
                it_surname=_get_surname(standard_names["ita"]),
                lt_surname=_get_surname(standard_names["lat"]),
                rm_surname=_get_surname(standard_names["roh"]),
                sex=cast(str, person.xpath("./sex/text()").get()),
                first_mention=person.xpath("./first_mention/text()").get(),
                last_mention=person.xpath("./last_mention/text()").get(),
                birth=person.xpath("./birth/text()").get(),
                death=person.xpath("./death/text()").get(),
            )
        )

    return Persons(entities=persons)


API_ADAPTER: tuple[tuple[str, Callable[[AsyncClient, str], Coroutine[Any, Any, Entities]]], ...] = (
    (PLACES_API, get_places),
    (KEYWORDS_API, get_keywords),
    (LEMMATA_API, get_lemmata),
    (FAMILIES_API, get_families),
    (ORGANIZATION_API, get_orgs),
    (PERSONS_API, get_persons),
)


async def fetch_entities(
    api_adapter_config: tuple[
        tuple[str, Callable[[AsyncClient, str], Coroutine[Any, Any, Entities]]], ...
    ] = API_ADAPTER,
) -> tuple[Entities, ...]:
    """Fetches entities from the configured APIs.

    To fetch entities from a different API, pass a tuple of URL and adapter function to the
    `api_adapter_config` argument. Will fetch in parallel using asyncio.

    Args:
        api_adapter_config: A tuple of tuples containing the URL and adapter function for each API.

    Returns:
        A tuple of entities fetched from the configured APIs.
    """
    async with AsyncClient(timeout=180) as client:
        async with TaskGroup() as group:
            tasks = [group.create_task(adapter(client, url)) for url, adapter in api_adapter_config]

        return tuple(task.result() for task in tasks)
