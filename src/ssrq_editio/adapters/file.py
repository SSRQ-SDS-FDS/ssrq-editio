from pathlib import Path
from typing import AsyncGenerator

import cachebox
from anyio import open_file
from anyio.to_thread import run_sync
from httpx import AsyncClient


@cachebox.cached(cachebox.TTLCache(0, ttl=43200))
async def load(dir: Path, name: str | Path) -> str:
    """Load content of a file in an async fashion.

    The loaded content is cached to avoid reading the file multiple times.
    The item will be removed from the cache after 12 hours.

    Args:
        dir (Path): Directory where the file is located.
        name (str | Path): Name of the file to load.

    Returns:
        str: Content of the file.
    """
    async with await open_file(dir / name, "r", encoding="utf-8") as f:  # pragma: no cover
        return await f.read()


async def write(dir: Path, name: str | Path, content: str) -> None:
    """Write content to a file in an async fashion.

    Args:
        dir (Path): Directory where the file is located.
        name (str | Path): Name of the file to write.
        content (str): Content to write to the file.
    """
    async with await open_file(dir / name, "w", encoding="utf-8") as f:
        await f.write(content)


async def load_via_http(url: str):
    """Load content of a file via HTTP in an async fashion.

    Args:
        url (str): URL of the file to load.

    Returns:
        str: Content of the file.
    """
    async with AsyncClient() as client:
        response = await client.get(url, follow_redirects=True)
        return response.text


async def stream(path: Path) -> AsyncGenerator[bytes, None]:
    """Stream the content of a file in an async fashion.

    Args:
        path (Path): Path to the file to stream.

    Yields:
        AsyncGenerator[bytes, None]: Bytes of the file.
    """
    async with await open_file(path, "rb") as f:
        while chunk := await f.read(1024):
            yield chunk


async def list_dir_content(dir: Path, pattern: str) -> tuple[Path, ...]:
    """List the content of a directory based on a pattern.

    Args:
        dir (Path): Directory to list the content of.
        pattern (str): Pattern to match the content against.

    Returns:
        tuple[Path, ...]: Tuple of paths matching the pattern.
    """
    return tuple(await run_sync(dir.glob, pattern))
