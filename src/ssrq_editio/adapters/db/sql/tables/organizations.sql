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
    fr_types TEXT NOT NULL
);
