from pathlib import Path

from aiosqlite import Connection

from ssrq_editio.adapters.db.config import SQL_DATA_DIR
from ssrq_editio.adapters.db.shared import store_batches
from ssrq_editio.adapters.file import load
from ssrq_editio.models.documents import Document, DocumentInfo

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


async def get_document_infos(
    connection: Connection,
    query: Path = SQL_DATA_DIR / "get_idno.sql",
) -> dict[str, DocumentInfo]:
    """Retrieve the document infos from the database.

    Args:
        connection (Connection): An aiosqlite Connection
        query (Path): The path to the query file

    Returns:
        dict[str, DocumentInfo]: A dictionary with the document UUID as key and the document info as value
    """
    sql_query = await load(dir=query.parent, name=query.name)
    result = await connection.execute_fetchall(sql_query)

    return {
        uuid: DocumentInfo(
            idno=idno, printed_idno=printed_idno, volume=volume, kanton=kanton, sort_key=sort_key
        )
        for uuid, idno, sort_key, printed_idno, volume, kanton in result
    }
