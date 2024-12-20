INSERT OR REPLACE INTO places (
    id,
    cs_name,
    de_name,
    fr_name,
    it_name,
    lt_name,
    nl_name,
    pl_name,
    rm_name,
    de_place_types,
    fr_place_types
) VALUES (
    ?, ?, ?, ?, ?, ?, ?, ?, ?, json(?), json(?)
);
