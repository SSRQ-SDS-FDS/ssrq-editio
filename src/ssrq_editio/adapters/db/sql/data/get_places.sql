SELECT
    places.id,
    places.cs_name,
    places.de_name,
    places.fr_name,
    places.it_name,
    places.lt_name,
    places.nl_name,
    places.pl_name,
    places.rm_name,
    places.de_place_types,
    places.fr_place_types,
    occurrences.occurrences
FROM places -- noqa: AM04
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
) AS occurrences ON places.id = occurrences.ref
WHERE
    (
        places.id LIKE '%' || :search || '%'
        OR places.cs_name LIKE '%' || :search || '%'
        OR places.de_name LIKE '%' || :search || '%'
        OR places.fr_name LIKE '%' || :search || '%'
        OR places.it_name LIKE '%' || :search || '%'
        OR places.lt_name LIKE '%' || :search || '%'
        OR places.nl_name LIKE '%' || :search || '%'
        OR places.pl_name LIKE '%' || :search || '%'
        OR places.rm_name LIKE '%' || :search || '%'
    ) AND (
        :occurrence IS ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    )
