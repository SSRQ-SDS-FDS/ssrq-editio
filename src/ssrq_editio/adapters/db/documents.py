from pathlib import Path

from aiosqlite import Connection

from ssrq_editio.adapters.db.config import SQL_DATA_DIR
from ssrq_editio.adapters.db.shared import store_batches
from ssrq_editio.adapters.file import load
from ssrq_editio.models.documents import Document

__all__ = [
    "initialize_document_data",
]


async def initialize_document_data(
    documents: tuple[Document, ...],
    connection: Connection,
    batch_size: int = 256,
    query: Path = SQL_DATA_DIR / "put_document.sql",
):
    sql_query = await load(dir=query.parent, name=query.name)
    await store_batches(
        connection,
        batch_size,
        sql_query,
        [doc.model_dump_sqlite() for doc in documents],
    )
