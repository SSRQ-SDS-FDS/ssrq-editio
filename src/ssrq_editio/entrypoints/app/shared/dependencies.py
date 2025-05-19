from pathlib import Path
from typing import Annotated, AsyncGenerator

import cachebox
from aiosqlite import Connection
from fastapi import Depends, Header, Query
from ssrq_utils.lang.display import Lang

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.file import load
from ssrq_editio.entrypoints.app.config import DB_NAME
from ssrq_editio.entrypoints.cli.config import TMP_SCHEMA
from ssrq_editio.services.documents import DocumentTransformer
from ssrq_editio.services.schema import SCHEMA_SRC, transpile_schema_to_translations

__all__ = ["DBDependency", "LangDependency", "TransformerDependency"]


async def get_lang(
    x_lang: Annotated[str | None, Header()] = None, lang: Annotated[str | None, Query()] = None
) -> Lang:
    if x_lang:
        return Lang.from_string(x_lang)
    if lang:
        return Lang.from_string(lang)
    return Lang.DE


LangDependency = Annotated[Lang, Depends(get_lang)]


async def db_connection() -> AsyncGenerator[Connection, None]:
    async for session in db_session(DB_NAME):
        yield session


DBDependency = Annotated[Connection, Depends(db_connection)]


@cachebox.cached(cache=cachebox.LRUCache(maxsize=1))
async def transpile_schema() -> Path:
    return await transpile_schema_to_translations(SCHEMA_SRC, TMP_SCHEMA)


SchemaDependency = Annotated[Path, Depends(transpile_schema)]


async def document_transformer(transpiled_schema: SchemaDependency) -> DocumentTransformer:
    return DocumentTransformer(
        transpiled_schema=await load(transpiled_schema.parent, transpiled_schema.name)
    )


TransformerDependency = Annotated[DocumentTransformer, Depends(document_transformer)]
