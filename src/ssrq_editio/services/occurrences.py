from collections import defaultdict

from ssrq_editio.adapters.db.documents import get_document_infos
from ssrq_editio.entrypoints.app.shared.dependencies import DBDependency
from ssrq_editio.models.documents import DocumentIdentificationDisplay


def group_and_sort_idnos(occurrences: list[str], idnos: dict[str, DocumentIdentificationDisplay]):
    mapped_occurrences = {idno: idnos[idno] for idno in occurrences}
    result: dict[str, dict[str, list[DocumentIdentificationDisplay]]] = defaultdict(
        lambda: defaultdict(list)
    )

    for d in mapped_occurrences.values():
        result[d.kanton][d.volume].append(d)

    for kanton in result:
        for volume in result[kanton]:
            result[kanton][volume].sort(key=lambda x: x.sort_key)

    return result


async def resolve_idnos_to_documents(
    connection: DBDependency, occurrences: list[str]
) -> list[DocumentIdentificationDisplay]:
    """Resolve ID numbers to document displays.

    Args:
        connection (DBDependency): The database connection.
        occurrences (list[str]): The list of ID numbers to resolve.

    Returns:
        list[DocumentIdentificationDisplay]: The list of resolved document displays.
    """
    return [v for _, v in (await get_document_infos(connection=connection)).items()]
