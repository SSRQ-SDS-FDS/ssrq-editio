CREATE TABLE IF NOT EXISTS occurrences
(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    uuid TEXT NOT NULL,
    ref TEXT NOT NULL,
    FOREIGN KEY (uuid) REFERENCES documents (uuid)
);

CREATE INDEX idx_occurrences_ref ON occurrences (ref);
