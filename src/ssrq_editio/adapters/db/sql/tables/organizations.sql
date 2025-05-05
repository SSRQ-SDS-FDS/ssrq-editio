-- The fields de_place_types and fr_place_types
-- are actually arrays of strings (serialized as JSON).
CREATE TABLE IF NOT EXISTS organizations
(
    id TEXT NOT NULL PRIMARY KEY,
    de_name TEXT NULL,
    fr_name TEXT NULL,
    it_name TEXT NULL,
    lt_name TEXT NULL,
    rm_name TEXT NULL,
    de_types TEXT NOT NULL,
    fr_types TEXT NOT NULL,
    location TEXT NULL
);

CREATE VIRTUAL TABLE IF NOT EXISTS organizations_fts USING fts5( -- noqa: PRS
    id UNINDEXED,
    de_name,
    fr_name,
    it_name,
    lt_name,
    rm_name
);

CREATE TRIGGER IF NOT EXISTS organizations_ai AFTER INSERT ON organizations BEGIN
    INSERT INTO organizations_fts (
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
