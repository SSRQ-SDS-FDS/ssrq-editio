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
LEFT JOIN (
    SELECT
        occurrences.ref,
        GROUP_CONCAT(occurrences.uuid, ',') AS occurrences
    FROM occurrences
    GROUP BY occurrences.ref
) AS occurrences ON keywords.id = occurrences.ref
WHERE
    keywords.id LIKE '%' || :search || '%'
    OR keywords.de_name LIKE '%' || :search || '%'
    OR keywords.fr_name LIKE '%' || :search || '%'
    OR keywords.it_name LIKE '%' || :search || '%'
    OR keywords.lt_name LIKE '%' || :search || '%'
