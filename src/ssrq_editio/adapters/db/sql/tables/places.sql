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

CREATE VIRTUAL TABLE IF NOT EXISTS persons_fts USING fts5( -- noqa: PRS
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

CREATE TRIGGER IF NOT EXISTS persons_ai AFTER INSERT ON persons BEGIN
    INSERT INTO persons_fts (
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
        cs_name,
        de_name,
        fr_name,
        it_name,
        lt_name,
        nl_name,
        pl_name,
        rm_name
    );
END;
