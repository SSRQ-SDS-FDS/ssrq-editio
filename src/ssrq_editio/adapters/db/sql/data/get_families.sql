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
    f.id,
    f.de_name,
    f.fr_name,
    f.it_name,
    f.lt_name,
    f.rm_name,
    f.first_mention,
    f.last_mention,
    f.location,
    occurrences.occurrences
FROM families AS f
LEFT JOIN entity_occurrences AS occurrences ON f.id = occurrences.ref
WHERE
    (
        :search = ''
        OR f.id LIKE '%' || :search || '%'
    ) AND (
        :occurrence IS ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    ) AND (
        :ids = ''
        OR f.id IN (SELECT ijt.value FROM JSON_EACH(:ids) AS ijt)
    )

UNION

SELECT -- noqa
    f.*,
    occurrences.occurrences
FROM families AS f
INNER JOIN families_fts AS fts ON f.id = fts.id
LEFT JOIN entity_occurrences AS occurrences ON f.id = occurrences.ref
WHERE :search <> '' AND families_fts MATCH :search; -- noqa
