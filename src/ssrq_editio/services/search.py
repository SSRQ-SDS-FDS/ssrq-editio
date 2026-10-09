from aiosqlite import Connection

from ssrq_editio.adapters.db.documents import get_documents_by_ft
from ssrq_editio.models.search import DocumentSearchHit, DocumentSearchResponse


async def search_documents(
    connection: Connection,
    query: str | None,
) -> DocumentSearchResponse:
    """Search documents using the same full-text implementation as the UI.

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
