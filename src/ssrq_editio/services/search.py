from typing import Sequence

from aiosqlite import Connection

from ssrq_editio.adapters.db.documents import get_all_documents, get_documents_by_ft
from ssrq_editio.models.documents import Document
from ssrq_editio.models.search import DocumentSearchHit, DocumentSearchResponse


async def find_documents(
    connection: Connection,
    query: str | None,
) -> Sequence[Document]:
    """Find documents, optionally matching a full-text query.

    Args:
        connection: An open SQLite connection.
        query: The full-text search query. None, empty or whitespace-only queries return
            all documents.

    Returns:
        All documents ordered by volume and document sort key, or full-text matches with
        snippets ordered by relevance.
    """
    if query is None or not query.strip():
        return await get_all_documents(connection=connection)

    return await get_documents_by_ft(connection=connection, search=query)


async def search_documents(
    connection: Connection,
    query: str | None,
) -> DocumentSearchResponse:
    """Search documents using the fulltext-search-adapter.

    This service is just a small wrapper, which is used to create a structed DocumentSearchResponse.

    Args:
        connection: An open SQLite connection.
        query: The full-text search query. ``None`` and empty queries return no results.

    Returns:
        DocumentSearchResponse: A compact search response containing the fields needed by API and UI consumers.
    """
    search_results = await get_documents_by_ft(connection=connection, search=query)

    return DocumentSearchResponse(
        query=query or "",
        results=[
            DocumentSearchHit(
                uuid=document.uuid,
                idno=document.idno,
                printed_idno=document.printed_idno,
                ft_match=document.ft_match,
                keywords=document.keywords,
            )
            for document in search_results
        ],
    )
