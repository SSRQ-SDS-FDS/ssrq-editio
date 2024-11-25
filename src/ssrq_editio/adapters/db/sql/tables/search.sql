CREATE TABLE IF NOT EXISTS search
(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    volume_title TEXT NOT NULL,
    document_title TEXT NOT NULL,
    summary TEXT NULL,
    content TEXT NULL,
    commentary TEXT NULL,
    uuid TEXT NOT NULL,
    FOREIGN KEY (uuid) REFERENCES documents (uuid)
);
