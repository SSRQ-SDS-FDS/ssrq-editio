INSERT OR REPLACE INTO persons (
    id,
    de_name,
    fr_name,
    it_name,
    lt_name,
    rm_name,
    de_surname,
    fr_surname,
    it_surname,
    lt_surname,
    rm_surname,
    sex,
    first_mention,
    last_mention,
    birth,
    death,
    location
) VALUES (
    ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, json(?)
);
