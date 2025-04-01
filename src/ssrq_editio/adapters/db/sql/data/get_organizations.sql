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
        org.id LIKE '%' || :search || '%'
        OR org.de_name LIKE '%' || :search || '%'
        OR org.fr_name LIKE '%' || :search || '%'
        OR org.it_name LIKE '%' || :search || '%'
        OR org.lt_name LIKE '%' || :search || '%'
        OR org.rm_name LIKE '%' || :search || '%'
    ) AND (
        :occurrence IS ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    )
