INSERT INTO volumes (id, name, kanton_id, title, prefix, pdf, literature) VALUES
(
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
