SELECT -- noqa
    d.*, -- noqa: AM04
    -fts.rank AS ft_score,
    -- TODO: Remove this fallback when API/MCP use the area-specific snippets.
    snippet(fts.documents_fulltext, -1, '<mark>', '</mark>', '...', 64)
        AS ft_match,
    snippet(fts.documents_fulltext, 1, '<mark>', '</mark>', '...', 64)
        AS title_match,
    snippet(fts.documents_fulltext, 2, '<mark>', '</mark>', '...', 64)
        AS summary_match,
    snippet(fts.documents_fulltext, 3, '<mark>', '</mark>', '...', 64)
        AS text_match,
    snippet(fts.documents_fulltext, 4, '<mark>', '</mark>', '...', 64)
        AS comment_match
FROM documents_fulltext AS fts
INNER JOIN documents AS d ON fts.uuid = d.uuid
WHERE
    fts.rank MATCH 'bm25(0.0, 1.7, 1.5, 1.2, 0.5)'
    AND fts.documents_fulltext MATCH (
        '{'
        || CASE WHEN :search_title THEN 'title ' ELSE '' END
        || CASE WHEN :search_summary THEN 'summary ' ELSE '' END
        || CASE WHEN :search_text THEN 'text ' ELSE '' END
        || CASE WHEN :search_comment THEN 'comment ' ELSE '' END
        || '}:(' || :search_term || ')'
    )
ORDER BY fts.rank
