INSERT INTO documents_fulltext (
    uuid,
    title,
    summary,
    text,
    comment
) VALUES (
    :uuid,
    :title,
    :summary,
    :text,
    :comment
);
