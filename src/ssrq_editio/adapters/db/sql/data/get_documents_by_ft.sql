SELECT -- noqa
    d.*, -- noqa: AM04
    -fts.rank AS ft_score,
    snippet(fts.documents_fulltext, 1, '<mark>', '</mark>', '...', 64)
        AS ft_match
FROM documents_fulltext AS fts
INNER JOIN documents AS d ON fts.uuid = d.uuid
WHERE fts.documents_fulltext MATCH :search_term
ORDER BY fts.rank
