SELECT
    v.id AS "key",
    v.sort_key,
    v.volume_type,
    v.name,
    k.short_name AS kanton,
    v.title,
    v.prefix,
    v.pdf,
    v.translated_pdf,
    v.literature,
    v.project_page,
    (
        SELECT GROUP_CONCAT(e.name, ',')
        FROM
            editors AS e
        WHERE e.volume_id = v.id
    ) AS editors,
    (
        SELECT JSON_GROUP_ARRAY(co.name)
        FROM
            collaborateurs AS co
        WHERE co.volume_id = v.id
    ) AS collaborateurs
FROM
    volumes AS v
INNER JOIN
    kantons AS k
    ON v.kanton_id = k.id
WHERE
    k.short_name = ?
GROUP BY
    v.id,
    v.name,
    k.short_name,
    v.title,
    v.volume_type,
    v.prefix,
    v.pdf,
    v.translated_pdf,
    v.literature,
    v.project_page
ORDER BY
    v.sort_key ASC;
