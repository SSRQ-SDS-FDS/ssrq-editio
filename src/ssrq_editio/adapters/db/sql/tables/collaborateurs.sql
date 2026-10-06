CREATE TABLE IF NOT EXISTS collaborateurs
(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    volume_id TEXT NOT NULL,
    UNIQUE (volume_id, name),
    FOREIGN KEY (volume_id) REFERENCES volumes (id)
);
