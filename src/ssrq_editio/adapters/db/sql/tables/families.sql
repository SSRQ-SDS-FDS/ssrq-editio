CREATE TABLE IF NOT EXISTS families
(
    id TEXT NOT NULL PRIMARY KEY,
    de_name TEXT NULL,
    fr_name TEXT NULL,
    it_name TEXT NULL,
    lt_name TEXT NULL,
    rm_name TEXT NULL,
    first_mention TEXT NULL,
    last_mention TEXT NULL
);

CREATE VIRTUAL TABLE IF NOT EXISTS families_fts USING fts5( -- noqa: PRS
    id UNINDEXED,
    de_name,
    fr_name,
    it_name,
    lt_name,
    rm_name
);

CREATE TRIGGER IF NOT EXISTS families_ai AFTER INSERT ON families BEGIN
    INSERT INTO families_fts (
        rowid,
        id,
        de_name,
        fr_name,
        it_name,
        lt_name,
        rm_name
    ) VALUES (
        new.rowid,
        new.id,
        new.de_name,
        new.fr_name,
        new.it_name,
        new.lt_name,
        new.rm_name
    );
END;
