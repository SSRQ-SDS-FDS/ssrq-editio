INSERT INTO occurrences (uuid, ref)
SELECT
    d.uuid,
    p.id
FROM documents AS d, persons AS p, json_each(d.entities) AS je
WHERE d.entities IS NOT NULL AND je.value = p.id
UNION ALL
SELECT
    d.uuid,
    pl.id
FROM documents AS d, places AS pl, json_each(d.entities) AS je
WHERE d.entities IS NOT NULL AND je.value = pl.id
UNION ALL
SELECT
    d.uuid,
    k.id
FROM documents AS d, keywords AS k, json_each(d.entities) AS je
WHERE d.entities IS NOT NULL AND je.value = k.id
UNION ALL
SELECT
    d.uuid,
    l.id
FROM documents AS d, lemmata AS l, json_each(d.entities) AS je
WHERE d.entities IS NOT NULL AND je.value = l.id;
-- ToDO: add support for orgs and families
