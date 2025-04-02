CREATE TABLE IF NOT EXISTS documents
(
    uuid TEXT NOT NULL PRIMARY KEY,
    idno TEXT NOT NULL,
    is_main INTEGER NOT NULL,
    sort_key REAL NOT NULL,
    de_orig_date TEXT NOT NULL,
    en_orig_date TEXT NOT NULL,
    fr_orig_date TEXT NOT NULL,
    it_orig_date TEXT NOT NULL,
    facs TEXT NULL,
    printed_idno TEXT NULL,
    volume_id TEXT NOT NULL,
    orig_place TEXT NULL,
    de_title TEXT NULL,
    fr_title TEXT NULL,
    entities TEXT NULL,
    source TEXT NULL,
    type TEXT NOT NULL,
    start_year_of_creation INTEGER NULL,
    end_year_of_creation INTEGER NULL,
    FOREIGN KEY (volume_id) REFERENCES volumes (id)
);

CREATE INDEX idx_documents_volume_id ON documents (volume_id);
