SELECT
    org.id,
    org.de_name,
    org.fr_name,
    org.it_name,
    org.lt_name,
    org.rm_name,
    org.de_types,
    org.fr_types,
    org.location,
    occurrences.occurrences
FROM organizations AS org
LEFT JOIN (
    SELECT
        occurrences.ref,
        GROUP_CONCAT(occurrences.uuid, ',') AS occurrences,
        (
            SELECT GROUP_CONCAT(documents.printed_idno)
            FROM documents
            WHERE documents.uuid = occurrences.uuid
        ) AS printed_idno
    FROM occurrences
    GROUP BY occurrences.ref
) AS occurrences ON org.id = occurrences.ref
WHERE
    (
        :search = ''
        OR org.id LIKE '%' || :search || '%'
    ) AND (
        :occurrence IS ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    ) AND (
        :ids = ''
        OR org.id IN (SELECT ijt.value FROM JSON_EACH(:ids) AS ijt)
    )

UNION

SELECT -- noqa
    p.*,
    NULL AS occurrences
FROM organizations AS p
INNER JOIN organizations_fts AS fts ON p.id = fts.id
WHERE :search <> '' AND organizations_fts MATCH :search; -- noqa
