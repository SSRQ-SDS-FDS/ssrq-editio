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
        :search = ''
        OR places.id LIKE '%' || :search || '%'
    ) AND (
        :occurrence IS ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    ) AND (
        :id_json = ''
        OR places.id IN (SELECT ijt.value FROM JSON_EACH(:id_json) AS ijt)
    )

UNION

SELECT -- noqa
    p.*,
    NULL AS occurrences
FROM places AS p
INNER JOIN places_fts AS fts ON p.id = fts.id
WHERE :search <> '' AND places_fts MATCH :search; -- noqa
