from typing import Annotated, AsyncGenerator

from aiosqlite import Connection
from fastapi import Depends, Header, Query
from ssrq_utils.lang.display import Lang

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.entrypoints.app.config import DB_NAME

__all__ = ["DBDependency", "LangDependency"]


async def get_lang(
    x_lang: Annotated[str | None, Header()] = None, lang: Annotated[str | None, Query()] = None
) -> Lang:
    if x_lang:
        return Lang.from_string(x_lang)
    if lang:
        return Lang.from_string(lang)
    return Lang.DE


async def db_connection() -> AsyncGenerator[Connection, None]:
    async for session in db_session(DB_NAME):
        yield session


LangDependency = Annotated[Lang, Depends(get_lang)]
DBDependency = Annotated[Connection, Depends(db_connection)]
