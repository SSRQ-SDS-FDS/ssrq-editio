CREATE TABLE IF NOT EXISTS documents
(
    uuid TEXT NOT NULL PRIMARY KEY,
    idno TEXT NOT NULL,
    is_main INTEGER NOT NULL,
    sort_key INTEGER NOT NULL,
    orig_date TEXT NOT NULL,
    facs INTEGER NOT NULL,
    printed_idno TEXT NOT NULL,
    volume_id INTEGER NOT NULL,
    orig_place TEXT NULL,
    FOREIGN KEY (volume_id) REFERENCES volumes (id),
    FOREIGN KEY (orig_place) REFERENCES places (id)
);

CREATE INDEX idx_documents_volume_id ON documents (volume_id);
CREATE INDEX idx_documents_is_main ON documents (is_main);
