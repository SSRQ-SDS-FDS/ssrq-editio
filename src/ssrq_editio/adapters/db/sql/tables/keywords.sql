CREATE TABLE IF NOT EXISTS keywords
(
    id TEXT NOT NULL PRIMARY KEY,
    de_name TEXT NULL,
    fr_name TEXT NULL,
    it_name TEXT NULL,
    lt_name TEXT NULL,
    de_definition TEXT NULL,
    fr_definition TEXT NULL,
    it_definition TEXT NULL
);

CREATE VIRTUAL TABLE IF NOT EXISTS keywords_fts USING fts5( -- noqa: PRS
    id UNINDEXED,
    de_name,
    fr_name,
    it_name,
    lt_name
);

CREATE TRIGGER IF NOT EXISTS keywords_ai AFTER INSERT ON keywords BEGIN
    INSERT INTO keywords_fts (
        rowid,
        id,
        de_name,
        fr_name,
        it_name,
        lt_name
    ) VALUES (
        new.rowid,
        new.id,
        new.de_name,
        new.fr_name,
        new.it_name,
        new.lt_name
    );
END;
