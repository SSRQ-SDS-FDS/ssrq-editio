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
        GROUP_CONCAT(occurrences.uuid, ',') AS occurrences
    FROM occurrences
    GROUP BY occurrences.ref
) AS occurrences ON places.id = occurrences.ref
WHERE
    places.id LIKE '%' || :name || '%'
    OR places.cs_name LIKE '%' || :name || '%'
    OR places.de_name LIKE '%' || :name || '%'
    OR places.fr_name LIKE '%' || :name || '%'
    OR places.it_name LIKE '%' || :name || '%'
    OR places.lt_name LIKE '%' || :name || '%'
    OR places.nl_name LIKE '%' || :name || '%'
    OR places.pl_name LIKE '%' || :name || '%'
    OR places.rm_name LIKE '%' || :name || '%'
