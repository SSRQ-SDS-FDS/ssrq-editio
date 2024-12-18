CREATE TABLE IF NOT EXISTS persons
(
    id TEXT NOT NULL PRIMARY KEY,
    de_name TEXT NULL,
    fr_name TEXT NULL,
    it_name TEXT NULL,
    lt_name TEXT NULL,
    rm_name TEXT NULL,
    sex TEXT NOT NULL,
    first_mention TEXT NULL,
    last_mention TEXT NULL,
    birth TEXT NULL,
    death TEXT NULL
);
