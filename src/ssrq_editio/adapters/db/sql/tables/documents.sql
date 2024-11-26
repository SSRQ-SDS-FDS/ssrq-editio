CREATE TABLE IF NOT EXISTS documents
(
    uuid TEXT NOT NULL PRIMARY KEY,
    idno TEXT NOT NULL,
    is_main INTEGER NOT NULL,
    sort_key REAL NOT NULL,
    orig_date TEXT NOT NULL,
    facs INTEGER NOT NULL,
    printed_idno TEXT NULL,
    volume_id INTEGER NOT NULL,
    orig_place TEXT NULL,
    FOREIGN KEY (volume_id) REFERENCES volumes (id),
    FOREIGN KEY (orig_place) REFERENCES places (id)
);

CREATE INDEX idx_documents_volume_id ON documents (volume_id);
