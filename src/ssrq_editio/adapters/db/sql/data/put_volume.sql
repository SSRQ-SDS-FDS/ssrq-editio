INSERT INTO volumes (
    id,
    sort_key,
    name,
    kanton_id,
    title,
    prefix,
    pdf,
    translated_pdf,
    literature,
    project_page
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
    ?,
    ?,
    ?
);
