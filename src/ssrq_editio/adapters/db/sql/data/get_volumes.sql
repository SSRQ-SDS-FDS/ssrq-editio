SELECT
    v.id AS "key",
    v.name,
    k.short_name AS kanton,
    v.title,
    v.pdf,
    v.literature,
    GROUP_CONCAT(e.name, ',') AS editors
FROM
    volumes AS v
LEFT JOIN
    editors AS e
    ON v.id = e.volume_id
INNER JOIN
    kantons AS k
    ON v.kanton_id = k.id
WHERE
    k.short_name = ?
ORDER BY
    v.id ASC;
