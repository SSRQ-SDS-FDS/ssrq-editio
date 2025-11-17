CREATE TABLE IF NOT EXISTS volumes
(
    id TEXT NOT NULL PRIMARY KEY,
    sort_key INTEGER NOT NULL,
    name TEXT NOT NULL,
    kanton_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    prefix TEXT NOT NULL,
    pdf TEXT NULL,
    literature TEXT NULL,
    FOREIGN KEY (kanton_id) REFERENCES kantons (id)
);

CREATE INDEX idx_volumes_kanton_id ON volumes (kanton_id);
CREATE INDEX idx_volumes_sort_key ON volumes (sort_key);
