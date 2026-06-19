WITH entity_occurrences AS (
    SELECT
        occurrences.ref,
        GROUP_CONCAT(occurrences.uuid, ',') AS occurrences,
        GROUP_CONCAT(documents.printed_idno, ',') AS printed_idno
    FROM occurrences
    LEFT JOIN documents ON occurrences.uuid = documents.uuid
    GROUP BY occurrences.ref
)

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
    p.location,
    occurrences.occurrences
FROM persons AS p
LEFT JOIN entity_occurrences AS occurrences ON p.id = occurrences.ref
WHERE
    (
        :search = ''
        OR p.id LIKE '%' || :search || '%'
    ) AND (
        :occurrence = ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    ) AND (
        :ids = ''
        OR p.id IN (SELECT ijt.value FROM JSON_EACH(:ids) AS ijt)
    )

UNION

SELECT -- noqa
    p.*,
    occurrences.occurrences
FROM persons AS p
INNER JOIN persons_fts AS fts ON p.id = fts.id
LEFT JOIN entity_occurrences AS occurrences ON p.id = occurrences.ref
WHERE :search <> '' AND persons_fts MATCH :search; -- noqa
