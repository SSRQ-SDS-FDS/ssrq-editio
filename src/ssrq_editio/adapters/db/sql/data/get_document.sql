SELECT * -- noqa
FROM documents
WHERE
    -- enables "fuzzy search"; so we don't need the SSRQ prefix
    idno LIKE '%' || :idno
    OR uuid = :idno
