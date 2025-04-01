INSERT OR REPLACE INTO organizations (
    id,
    de_name,
    fr_name,
    it_name,
    lt_name,
    rm_name,
    de_types,
    fr_types,
    location
) VALUES (
    ?, ?, ?, ?, ?, ?, json(?), json(?), json(?)
);
