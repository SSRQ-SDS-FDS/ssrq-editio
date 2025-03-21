SELECT
    MAX(CASE WHEN docs.facs IS NOT NULL THEN 1 ELSE 0 END) AS has_facs,
    JSON_GROUP_ARRAY(DISTINCT docs.type) AS document_types,
    NULL AS first_year,
    NULL AS last_year
FROM documents AS docs
WHERE docs.volume_id = :volume_id; 