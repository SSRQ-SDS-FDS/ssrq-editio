-- ToDo: Improve the query by fixing all linter errors and warnings
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
        WHEN :facs = 1
            THEN
                CASE
                    WHEN docs.facs IS NOT NULL THEN docs.facs
                    -- just a placeholder, the actual value is not important
                    WHEN sub_docs_facs.facs IS NOT NULL THEN '[]'
                END
        ELSE docs.facs
    END AS facs,
    docs.printed_idno,
    docs.volume_id,
    docs.orig_place,
    docs.de_title,
    docs.fr_title,
    docs.entities,
    docs.type,
    (
        SELECT json_group_array(sub_docs.idno)
        FROM documents AS sub_docs
        WHERE
            sub_docs.volume_id = docs.volume_id
            AND sub_docs.is_main = 0
            AND cast(sub_docs.sort_key AS INT) = cast(docs.sort_key AS INT)
        ORDER BY sub_docs.sort_key ASC
    ) AS sub_documents
FROM documents AS docs
LEFT JOIN (
    SELECT
        volume_id,
        sort_key,
        facs
    FROM documents
    WHERE is_main = 0 AND facs IS NOT NULL
) AS sub_docs_facs
    ON
        sub_docs_facs.volume_id = docs.volume_id
        AND cast(sub_docs_facs.sort_key AS INT) = cast(docs.sort_key AS INT)
WHERE
    (
        docs.volume_id = :volume_id
        AND docs.is_main = 1
        AND (
            docs.idno LIKE '%' || :search || '%'
            OR docs.printed_idno LIKE '%' || :search || '%'
            OR docs.de_title LIKE '%' || :search || '%'
            OR docs.fr_title LIKE '%' || :search || '%'
        )
    )
    AND (
        :facs IS NULL
        OR :facs != 1
        OR docs.facs IS NOT NULL
        OR sub_docs_facs.facs IS NOT NULL
    )
    AND (
        :type IS NULL
        OR docs.type = :type
    )
ORDER BY docs.sort_key ASC;
