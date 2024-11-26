SELECT
    k.short_name,
    k.de_title,
    k.fr_title,
    k.it_title,
    GROUP_CONCAT(ki.filename, ', ') AS filenames,
    (
        SELECT COUNT(*)
        FROM documents AS d
        INNER JOIN volumes AS v ON d.volume_id = v.id
        WHERE v.kanton_id = k.id
    ) AS docs
FROM
    kantons AS k
LEFT JOIN
    kanton_images AS ki
    ON k.id = ki.kanton_id
GROUP BY
    k.id, k.short_name, k.de_title, k.fr_title, k.it_title
ORDER BY
    k.id ASC;
