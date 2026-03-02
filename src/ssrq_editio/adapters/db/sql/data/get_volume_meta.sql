SELECT
    MIN(
        COALESCE(docs.start_year_of_creation, docs.end_year_of_creation)
    ) AS first_year,
    MAX(
        COALESCE(docs.end_year_of_creation, docs.start_year_of_creation)
    ) AS last_year,
    MAX(CASE WHEN docs.facs IS NOT NULL THEN 1 ELSE 0 END) AS has_facs,
    JSON_GROUP_ARRAY(DISTINCT docs.type) AS document_types
FROM documents AS docs
WHERE docs.volume_id = :volume_id;
