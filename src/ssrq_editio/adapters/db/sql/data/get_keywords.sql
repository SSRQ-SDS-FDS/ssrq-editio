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
    keywords.id,
    keywords.de_name,
    keywords.fr_name,
    keywords.it_name,
    keywords.lt_name,
    keywords.de_definition,
    keywords.fr_definition,
    keywords.it_definition,
    occurrences.occurrences
FROM keywords
LEFT JOIN entity_occurrences AS occurrences ON keywords.id = occurrences.ref
WHERE
    (
        :search = ''
        OR keywords.id LIKE '%' || :search || '%'
    ) AND (
        :occurrence IS ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    ) AND (
        :ids = ''
        OR keywords.id IN (SELECT ijt.value FROM JSON_EACH(:ids) AS ijt)
    )

UNION

SELECT -- noqa
    k.*,
    occurrences.occurrences
FROM keywords AS k
INNER JOIN keywords_fts AS fts ON k.id = fts.id
LEFT JOIN entity_occurrences AS occurrences ON k.id = occurrences.ref
WHERE :search <> '' AND keywords_fts MATCH :search; -- noqa
