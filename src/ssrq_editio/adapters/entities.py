from asyncio import TaskGroup
from os import getenv
from typing import Any, Callable, Coroutine, cast

from httpx import AsyncClient
from httpx._status_codes import codes
from parsel import Selector

from ssrq_editio.models.entities import Entities, Place, Places

PLACES_API = getenv("PLACES_API", "https://loci.ssrq-sds-fds.ch/views/places4index-v3.xq")


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
