SELECT EXISTS(
    SELECT 1
    FROM documents AS docs
    WHERE
        docs.volume_id = :volume_id
        AND docs.facs IS NOT NULL
    LIMIT 1
);
