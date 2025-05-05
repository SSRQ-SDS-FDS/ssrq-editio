CREATE TABLE IF NOT EXISTS places
(
    id TEXT NOT NULL PRIMARY KEY,
    cs_name TEXT NULL,
    de_name TEXT NULL,
    fr_name TEXT NULL,
    it_name TEXT NULL,
    lt_name TEXT NULL,
    nl_name TEXT NULL,
    pl_name TEXT NULL,
    rm_name TEXT NULL,
    de_place_types TEXT NOT NULL,
    fr_place_types TEXT NOT NULL
);

CREATE VIRTUAL TABLE IF NOT EXISTS places_fts USING fts5( -- noqa: PRS
    id UNINDEXED,
    cs_name,
    de_name,
    fr_name,
    it_name,
    lt_name,
    nl_name,
    pl_name,
    rm_name
);
CREATE TRIGGER IF NOT EXISTS places_ai AFTER INSERT ON places BEGIN
    INSERT INTO places_fts (
        rowid,
        id,
        cs_name,
        de_name,
        fr_name,
        it_name,
        lt_name,
        nl_name,
        pl_name,
        rm_name
    ) VALUES (
        new.rowid,
        new.id,
        new.cs_name,
        new.de_name,
        new.fr_name,
        new.it_name,
        new.lt_name,
        new.nl_name,
        new.pl_name,
        new.rm_name
    );
END;
