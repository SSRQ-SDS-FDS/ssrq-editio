WITH target_document AS (
    SELECT volume_id
    FROM documents
    WHERE
        idno LIKE '%' || :idno
        OR uuid = :idno
),
filtered_documents AS (
    SELECT d.*
    FROM documents d
    JOIN target_document t ON d.volume_id = t.volume_id
),
document_extended AS (
    SELECT
        *,
        LAG(idno) OVER (ORDER BY sort_key) AS previous_document,
        LEAD(idno) OVER (ORDER BY sort_key) AS next_document
    FROM filtered_documents
)
SELECT *
FROM document_extended
WHERE
    idno LIKE '%' || :idno
    OR uuid = :idno;
