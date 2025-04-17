SELECT
    v.id AS "key",
    v.name,
    k.short_name AS kanton,
    v.title,
    v.prefix,
    v.pdf,
    v.literature,
    GROUP_CONCAT(e.name, ',') AS editors
FROM
    volumes AS v
INNER JOIN
    kantons AS k
    ON v.kanton_id = k.id
LEFT JOIN
    editors AS e
    ON v.id = e.volume_id
WHERE
    k.short_name = ?
GROUP BY
    v.id, v.name, k.short_name, v.title, v.prefix, v.pdf, v.literature
ORDER BY
    v.id ASC;
