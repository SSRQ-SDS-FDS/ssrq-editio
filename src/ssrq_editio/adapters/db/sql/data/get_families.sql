SELECT
    f.id,
    f.de_name,
    f.fr_name,
    f.it_name,
    f.lt_name,
    f.rm_name,
    f.first_mention,
    f.last_mention,
    occurrences.occurrences
FROM families AS f
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
) AS occurrences ON f.id = occurrences.ref
WHERE
    (
        f.id LIKE '%' || :search || '%'
        OR f.de_name LIKE '%' || :search || '%'
        OR f.fr_name LIKE '%' || :search || '%'
        OR f.it_name LIKE '%' || :search || '%'
        OR f.lt_name LIKE '%' || :search || '%'
        OR f.rm_name LIKE '%' || :search || '%'
    ) AND (
        :occurrence IS ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    )
