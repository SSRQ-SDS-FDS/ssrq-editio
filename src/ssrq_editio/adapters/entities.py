from asyncio import TaskGroup
from os import getenv
from typing import Any, Callable, Coroutine, cast

from httpx import AsyncClient
from httpx._status_codes import codes
from parsel import Selector

from ssrq_editio.models.entities import Entities, Keyword, Keywords, Lemma, Lemmata, Place, Places

PLACES_API = getenv("PLACES_API", "https://loci.ssrq-sds-fds.ch/views/places4index-v3.xq")
KEYWORDS_API = getenv("KEYWORDS_API", "https://termini.ssrq-sds-fds.ch/views/keywords4index-v3.xq")
LEMMATA_API = getenv("LEMMATA_API", "https://termini.ssrq-sds-fds.ch/views/lemmas4index-v3.xq")


class APIFetchError(Exception):
    pass


async def get_places(client: AsyncClient, url: str) -> Places:
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
                occurrences=None,
            )
            for place in tree.xpath(".//place")
        ]
    )


async def get_keywords(client: AsyncClient, url: str) -> Keywords:
    response = await client.get(url, follow_redirects=True)

    if response.status_code != codes.OK:
        raise APIFetchError(f"Failed to fetch keywords from {url}")

    tree = Selector(response.text, type="xml")

    return Keywords(
        entities=[
            Keyword(
                id=cast(str, keyword.xpath("./@id").get()),
                occurrences=None,
                de_name=keyword.xpath("./name[@lang='deu']/text()").get(),
                fr_name=keyword.xpath("./name[@lang='fra']/text()").get(),
                it_name=keyword.xpath("./name[@lang='ita']/text()").get(),
                lt_name=None,
            )
            for keyword in tree.xpath(".//keyword")
        ]
    )


async def get_lemmata(client: AsyncClient, url: str) -> Lemmata:
    response = await client.get(url, follow_redirects=True)

    if response.status_code != codes.OK:
        raise APIFetchError(f"Failed to fetch keywords from {url}")

    tree = Selector(response.text, type="xml")

    return Lemmata(
        entities=[
            Lemma(
                id=cast(str, keyword.xpath("./@id").get()),
                occurrences=None,
                de_name=keyword.xpath("./stdName[@lang='deu']/text()").get(),
                fr_name=keyword.xpath("./stdName[@lang='fra']/text()").get(),
                it_name=keyword.xpath("./stdName[@lang='ita']/text()").get(),
                lt_name=keyword.xpath("./stdName[@lang='lat']/text()").get(),
                rm_name=keyword.xpath("./stdName[@lang='roh']/text()").get(),
            )
            for keyword in tree.xpath(".//lemma")
        ]
    )


API_ADAPTER: tuple[tuple[str, Callable[[AsyncClient, str], Coroutine[Any, Any, Entities]]], ...] = (
    (PLACES_API, get_places),
)


async def fetch_entities(
    api_adapter_config: tuple[
        tuple[str, Callable[[AsyncClient, str], Coroutine[Any, Any, Entities]]], ...
    ] = API_ADAPTER,
) -> tuple[Entities, ...]:
    async with AsyncClient() as client:
        async with TaskGroup() as group:
            tasks = [group.create_task(adapter(client, url)) for url, adapter in api_adapter_config]

        return tuple(task.result() for task in tasks)
