WITH main_documents AS (
    SELECT
        docs.*,
        CAST(docs.sort_key AS INT) AS sort_key_int
    FROM documents AS docs
    WHERE
        docs.volume_id = :volume_id
        AND docs.is_main = 1
        -- Some source XML marks opening documents as main documents.
        -- Keep them out of the volume list until the source data
        -- can be corrected.
        AND docs.idno NOT GLOB '*-[0-9.]*[A-Za-z][0-9.]*-1'
),

documents_with_flags AS (
    SELECT
        docs.*,
        EXISTS(
            SELECT 1
            FROM documents AS sub_docs
            WHERE
                sub_docs.volume_id = docs.volume_id
                AND sub_docs.is_main = 0
                AND CAST(sub_docs.sort_key AS INT) = docs.sort_key_int
                AND sub_docs.facs IS NOT NULL
        ) AS has_sub_document_facs,
        (
            SELECT JSON_GROUP_ARRAY(sub_docs.idno)
            FROM documents AS sub_docs
            WHERE
                sub_docs.volume_id = docs.volume_id
                AND sub_docs.is_main = 0
                AND CAST(sub_docs.sort_key AS INT) = docs.sort_key_int
            ORDER BY sub_docs.sort_key ASC
        ) AS sub_documents
    FROM main_documents AS docs
)
SELECT -- noqa: disable=all
    docs.uuid,
    docs.idno,
    docs.is_main,
    docs.sort_key,
    docs.de_orig_date,
    docs.en_orig_date,
    docs.fr_orig_date,
    docs.it_orig_date,
    CASE
        WHEN :facs = 1 AND docs.facs IS NULL AND docs.has_sub_document_facs = 1 THEN '[]'
        ELSE docs.facs
    END AS facs,
    docs.printed_idno,
    docs.volume_id,
    docs.orig_place,
    docs.de_title,
    docs.fr_title,
    docs.entities,
    docs.type,
    docs.start_year_of_creation,
    docs.end_year_of_creation,
    docs.sub_documents
FROM documents_with_flags AS docs
WHERE
    (
        docs.idno LIKE '%' || :search || '%'
        OR docs.printed_idno LIKE '%' || :search || '%'
        OR docs.de_title LIKE '%' || :search || '%'
        OR docs.fr_title LIKE '%' || :search || '%'
    )
    AND (
        :facs IS NULL
        OR :facs != 1
        OR docs.facs IS NOT NULL
        OR docs.has_sub_document_facs = 1
    )
    AND (
        :type IS NULL
        OR docs.type = :type
    )
    AND (
        (
            :range_start IS NULL
            OR (docs.start_year_of_creation IS NOT NULL AND docs.start_year_of_creation >= :range_start)
            OR (docs.end_year_of_creation IS NOT NULL AND docs.end_year_of_creation >= :range_start)
        )
        AND
        (
            :range_end IS NULL
            OR (docs.start_year_of_creation IS NOT NULL AND docs.start_year_of_creation <= :range_end)
            OR (docs.end_year_of_creation IS NOT NULL AND docs.end_year_of_creation <= :range_end)
        )
    )
ORDER BY docs.sort_key ASC;
