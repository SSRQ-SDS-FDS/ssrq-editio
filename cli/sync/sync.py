import mimetypes
import os
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

from httpx import AsyncClient, BasicAuth, codes
from loguru import logger
from pydantic import BaseModel
from watchfiles import Change, awatch

from cli.config import BUILD_CONFIG
from cli.css import handle as css_handle


class ExistServerConfig(BaseModel):
    url: str
    port: str
    user: str
    password: str
    collection: str
    local_project_root: Path


@dataclass
class ExistEndpoints:
    delete: str = "/exist/apps/atom-editor/delete"
    run: str = "/exist/apps/atom-editor/run"
    store: str = "/exist/apps/atom-editor/store"


class HttpReturnTypes(Enum):
    OK = 0
    ERROR = 1


async def sync_folder(
    config: ExistServerConfig,
    watch_dir: Path,
    endpoints: ExistEndpoints = ExistEndpoints(),
):
    _add_to_mimetypes()
    async with AsyncClient() as async_client:
        check = await check_exist_server(
            config=config, endpoints=endpoints, async_http_client=async_client
        )
        if check is HttpReturnTypes.ERROR:
            logger.error(f"Could not connect to eXist server on {config.url}:{config.port}")
            return

        logger.info(f"Watching {watch_dir} for changes...")
        async for changes in awatch(watch_dir, recursive=True):
            for change in changes:
                await _handle_change(change, config, endpoints, async_client)


def _add_to_mimetypes():
    mimetypes.add_type("application/xquery", ".xq")
    mimetypes.add_type("application/xquery", ".xql")
    mimetypes.add_type("application/xquery", ".xqm")
    mimetypes.add_type("application/xquery", ".xquery")
    mimetypes.add_type("application/xml", ".odd")


async def _handle_change(
    change: tuple[Change, str],
    config: ExistServerConfig,
    endpoints: ExistEndpoints,
    async_client: AsyncClient,
):
    match change:
        case _, file if (file.endswith(".css") or file.endswith(".config.js")) and "src" in file:
            logger.info(f"Style sources changed in: {file}")
            logger.info("Compiling new styles.css...")
            css_handle.compile_css(BUILD_CONFIG.css.source, BUILD_CONFIG.css.target)
        case Change.modified, _:
            logger.info(f"File {change[1]} changed")
            await store(
                config=config,
                endpoints=endpoints,
                file_path=Path(change[1]),
                file_is_added=False,
                async_http_client=async_client,
            )
        case Change.added, _:
            file_path = Path(change[1])
            if file_path.is_dir():
                logger.info(f"Directory {change[1]} added")
                await create_collection(
                    config=config,
                    endpoints=endpoints,
                    collection=file_path,
                    async_http_client=async_client,
                )
            else:
                logger.info(f"File {change[1]} added")
                await store(
                    config=config,
                    endpoints=endpoints,
                    file_path=Path(change[1]),
                    file_is_added=True,
                    async_http_client=async_client,
                )
        case Change.deleted, _:
            logger.info(f"File or directory {change[1]} deleted")
            await delete(
                config=config,
                endpoints=endpoints,
                file_or_collection=Path(change[1]),
                async_http_client=async_client,
            )
        case _:
            logger.error(f"Unknown change: {change}")


async def check_exist_server(
    config: ExistServerConfig, endpoints: ExistEndpoints, async_http_client: AsyncClient
) -> HttpReturnTypes:
    return await get_request_to_exist(
        config=config,
        endpoint=endpoints.run,
        query="system:get-version()",
        async_http_client=async_http_client,
    )


async def store(
    config: ExistServerConfig,
    endpoints: ExistEndpoints,
    file_path: Path,
    file_is_added: bool,
    async_http_client: AsyncClient,
) -> HttpReturnTypes:
    rel_path = file_path.relative_to(config.local_project_root)
    url = f"{config.url}:{config.port}{endpoints.store}{config.collection}/{rel_path}"
    content_type = mimetypes.guess_type(file_path)[0]

    logger.info(f"Uploading {rel_path} as {content_type}...")

    with open(file_path, "rb") as f:
        auth_header = BasicAuth(config.user, config.password)
        response = await async_http_client.put(
            url,
            auth=auth_header,
            headers={
                "Content-Type": content_type if content_type is not None else "application/xml",
                "Content-Length": str(os.path.getsize(file_path)),
            },
            content=f.read(),
        )

    if response.status_code != codes.OK or response.json().get("status") == "error":
        logger.error(f"Upload of {rel_path} failed: {response.json().get('message')}")
        return HttpReturnTypes.ERROR

    if content_type == "application/xquery" and file_is_added:
        xquery_snippet = f"sm:chmod(xs:anyURI('{config.collection}/{rel_path}'), 'rwxr-xr-x')"
        resp_code = await get_request_to_exist(
            config,
            endpoints.run,
            xquery_snippet,
            async_http_client=async_http_client,
        )
        if resp_code is HttpReturnTypes.ERROR:
            logger.error(f"Uploaded {rel_path} – but could not set file-permissions")
        else:
            logger.success(f"Successfully added {rel_path}")
        return resp_code

    logger.success(f"Successfully uploaded {rel_path}")

    return HttpReturnTypes.OK


async def create_collection(
    config: ExistServerConfig,
    endpoints: ExistEndpoints,
    collection: Path,
    async_http_client: AsyncClient,
):
    rel_path = collection.relative_to(config.local_project_root)
    logger.info(f"Creating collection {rel_path}...")
    resp_code = await get_request_to_exist(
        config,
        endpoints.run,
        f"""fold-left(tokenize("{rel_path}", "/"), "{config.collection}",
        function($parent, $component) {{
            xmldb:create-collection($parent, $component)
        }})""",
        async_http_client,
    )

    if resp_code is HttpReturnTypes.ERROR:
        logger.error(f"Could not create collection {rel_path}")
        return resp_code

    logger.success(f"Successfully created collection {rel_path}")
    return resp_code


async def delete(
    config: ExistServerConfig,
    endpoints: ExistEndpoints,
    file_or_collection: Path,
    async_http_client: AsyncClient,
) -> HttpReturnTypes:
    rel_path = file_or_collection.relative_to(config.local_project_root)
    url = f"{config.url}:{config.port}{endpoints.delete}{config.collection}/{rel_path}"
    auth_header = BasicAuth(config.user, config.password)
    response = await async_http_client.get(url, auth=auth_header)

    if response.status_code != codes.OK:
        logger.error(f"Error while deleting {rel_path}: {response.text}")
        return HttpReturnTypes.ERROR

    logger.success(f"Successfully deleted {rel_path}")
    return HttpReturnTypes.OK


async def get_request_to_exist(
    config: ExistServerConfig,
    endpoint: str,
    query: str,
    async_http_client: AsyncClient,
) -> HttpReturnTypes:
    url = f"{config.url}:{config.port}{endpoint}"
    auth_header = BasicAuth(config.user, config.password)
    headers = {"Content-Type": "application/json"}

    response = await async_http_client.get(
        url,
        auth=auth_header,
        headers=headers,
        params={"q": query},
        follow_redirects=True,
    )

    if response.status_code != codes.OK:
        logger.error(f"Error while executing query: {response.text}")
        return HttpReturnTypes.ERROR

    return HttpReturnTypes.OK
