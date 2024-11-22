CREATE TABLE IF NOT EXISTS kantons
(
    id INTEGER NOT NULL,
    short_name LIST NOT NULL,
    de_title TEXT NOT NULL,
    fr_title TEXT NULL,
    it_title TEXT NULL,
    PRIMARY KEY (id)
);
