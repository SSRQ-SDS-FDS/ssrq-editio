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
LEFT JOIN entity_occurrences AS occurrences ON places.id = occurrences.ref
WHERE
    (
        :search = ''
        OR places.id LIKE '%' || :search || '%'
    ) AND (
        :occurrence IS ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    ) AND (
        :ids = ''
        OR places.id IN (SELECT ijt.value FROM JSON_EACH(:ids) AS ijt)
    )

UNION

SELECT -- noqa
    p.*,
    occurrences.occurrences
FROM places AS p
INNER JOIN places_fts AS fts ON p.id = fts.id
LEFT JOIN entity_occurrences AS occurrences ON p.id = occurrences.ref
WHERE :search <> '' AND places_fts MATCH :search; -- noqa
