SELECT p.* -- noqa: AM04
FROM persons AS p
WHERE
    :search = ''
    OR p.id LIKE '%' || :search || '%'

UNION

SELECT p.*
FROM persons AS p
INNER JOIN persons_fts AS fts ON p.id = fts.id
WHERE :search <> '' AND persons_fts MATCH :search; -- noqa
