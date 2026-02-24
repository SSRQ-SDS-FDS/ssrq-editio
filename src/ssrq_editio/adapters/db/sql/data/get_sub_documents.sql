WITH main_doc AS (
    SELECT
        volume_id,
        CAST(sort_key AS INT) AS sort_key_int
    FROM documents
    WHERE idno LIKE '%' || :idno OR uuid = :idno
    LIMIT 1
)

SELECT -- noqa
    *
FROM documents
WHERE
    is_main = 0
    AND volume_id = (SELECT main_doc.volume_id FROM main_doc)
    AND CAST(sort_key AS INT) = (SELECT main_doc.sort_key_int FROM main_doc)
ORDER BY sort_key ASC;
