INSERT OR REPLACE INTO families (
    id,
    de_name,
    fr_name,
    it_name,
    lt_name,
    rm_name,
    first_mention,
    last_mention,
    location
) VALUES (
    ?, ?, ?, ?, ?, ?, ?, ?, ?
);
