SELECT
    lemmata.id,
    lemmata.de_name,
    lemmata.fr_name,
    lemmata.it_name,
    lemmata.lt_name,
    lemmata.rm_name,
    lemmata.de_definition,
    lemmata.fr_definition,
    lemmata.it_definition,
    occurrences.occurrences
FROM lemmata -- noqa: AM04
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
) AS occurrences ON lemmata.id = occurrences.ref
WHERE
    (
        lemmata.id LIKE '%' || :search || '%'
        OR lemmata.de_name LIKE '%' || :search || '%'
        OR lemmata.fr_name LIKE '%' || :search || '%'
        OR lemmata.it_name LIKE '%' || :search || '%'
        OR lemmata.lt_name LIKE '%' || :search || '%'
        OR lemmata.rm_name LIKE '%' || :search || '%'
    ) AND (
        :occurrence IS ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    )
