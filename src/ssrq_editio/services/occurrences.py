from collections import defaultdict

from ssrq_editio.models.documents import DocumentIdentificationDisplay


def group_and_sort_idnos(occurrenes: list[str], idnos: dict[str, DocumentIdentificationDisplay]):
    mapped_occurrences = {idno: idnos[idno] for idno in occurrenes}
    result: dict[str, dict[str, list[DocumentIdentificationDisplay]]] = defaultdict(
        lambda: defaultdict(list)
    )

    for d in mapped_occurrences.values():
        result[d.kanton][d.volume].append(d)

    for kanton in result:
        for volume in result[kanton]:
            result[kanton][volume].sort(key=lambda x: x.sort_key)

    return result
