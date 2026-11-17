SELECT -- noqa
    d.* -- noqa: AM04
FROM documents AS d
ORDER BY d.volume_id, d.sort_key, d.idno, d.uuid;
