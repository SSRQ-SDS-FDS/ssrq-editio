SELECT
    p.id,
    p.de_name,
    p.fr_name,
    p.it_name,
    p.lt_name,
    p.rm_name,
    p.de_surname,
    p.fr_surname,
    p.it_surname,
    p.lt_surname,
    p.rm_surname,
    p.sex,
    p.first_mention,
    p.last_mention,
    p.birth,
    p.death,
    occurrences.occurrences
FROM persons AS p
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
) AS occurrences ON p.id = occurrences.ref
WHERE
    (
        :search = ''
        OR p.id LIKE '%' || :search || '%'
    ) AND (
        :occurrence IS ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    )

UNION

SELECT -- noqa
    p.*,
    NULL AS occurrences
FROM persons AS p
INNER JOIN persons_fts AS fts ON p.id = fts.id
WHERE :search <> '' AND persons_fts MATCH :search; -- noqa
