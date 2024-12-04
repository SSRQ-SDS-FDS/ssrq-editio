SELECT
    v.id as key,
    v.name,
    k.short_name as kanton,
    v.title,
    v.pdf,
    v.literature,
    GROUP_CONCAT(e.name, ',') AS editors
FROM
    volumes as v
LEFT JOIN
    editors as e
    ON v.id = e.volume_id
JOIN
    kantons as k
    ON v.kanton_id = k.id
WHERE
    k.short_name = ?
ORDER BY
    v.id ASC;
