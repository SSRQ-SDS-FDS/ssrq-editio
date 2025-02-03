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
        GROUP_CONCAT(occurrences.uuid, ',') AS occurrences
    FROM occurrences
    GROUP BY occurrences.ref
) AS occurrences ON f.id = occurrences.ref
WHERE
    :search = ''
    OR f.id LIKE '%' || :search || '%'

UNION

SELECT -- noqa
    f.*,
    NULL AS occurrences
FROM families AS f
INNER JOIN families_fts AS fts ON f.id = fts.id
WHERE :search <> '' AND families_fts MATCH :search; -- noqa
