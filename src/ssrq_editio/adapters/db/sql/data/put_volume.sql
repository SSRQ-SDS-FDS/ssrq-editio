INSERT INTO volumes (
    id, sort_key, name, kanton_id, title, prefix, pdf, literature
) VALUES
(
    ?,
    ?,
    ?,
    (
        SELECT id FROM kantons
        WHERE short_name = ?
    ),
    ?,
    ?,
    ?,
    ?
);
