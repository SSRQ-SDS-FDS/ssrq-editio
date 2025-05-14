SELECT
    f.id,
    f.de_name,
    f.fr_name,
    f.it_name,
    f.lt_name,
    f.rm_name,
    f.first_mention,
    f.last_mention,
    f.location,
    occurrences.occurrences
FROM families AS f
LEFT JOIN (
    SELECT
        occurrences.ref,
        GROUP_CONCAT(occurrences.uuid, ',') AS occurrences,
        (
            SELECT GROUP_CONCAT(documents.printed_idno)
            FROM documents
            WHERE documents.uuid = occurrences.uuid
        ) AS printed_idno
    FROM occurrences
    GROUP BY occurrences.ref
) AS occurrences ON f.id = occurrences.ref
WHERE
    (
        :search = ''
        OR f.id LIKE '%' || :search || '%'
    ) AND (
        :occurrence IS ''
        OR occurrences.printed_idno LIKE '%' || :occurrence || '%'
    ) AND (
        :id_json = ''
        OR f.id IN (SELECT ijt.value FROM JSON_EACH(:id_json) AS ijt)
    )


UNION

SELECT -- noqa
    f.*,
    NULL AS occurrences
FROM families AS f
INNER JOIN families_fts AS fts ON f.id = fts.id
WHERE :search <> '' AND families_fts MATCH :search; -- noqa
