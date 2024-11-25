CREATE TABLE IF NOT EXISTS volumes
(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    kanton_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    pdf TEXT NULL,
    literature TEXT NULL,
    FOREIGN KEY (kanton_id) REFERENCES kantons (id)
);

CREATE INDEX idx_volumes_kanton_id ON volumes (kanton_id);
