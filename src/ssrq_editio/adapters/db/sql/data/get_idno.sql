--- This query returns essential information
--- about a document, based on its IDNO.
SELECT
    d.uuid,
    d.idno,
    d.sort_key,
    d.printed_idno,
    v.name AS volume,
    k.short_name AS kanton
FROM documents AS d
LEFT JOIN volumes AS v ON d.volume_id = v.id
LEFT JOIN kantons AS k ON v.kanton_id = k.id;
