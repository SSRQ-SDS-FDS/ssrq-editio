CREATE VIRTUAL TABLE  IF NOT EXISTS search  -- noqa
USING fts5(  -- noqa
    volume_title,
    document_title,
    summary,
    content,
    commentary,
    uuid UNINDEXED
);
