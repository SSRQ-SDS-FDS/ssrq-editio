CREATE TABLE IF NOT EXISTS persons_places
(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    persons_id TEXT NOT NULL,
    places_id TEXT NOT NULL,
    FOREIGN KEY (persons_id) REFERENCES persons (id),
    FOREIGN KEY (places_id) REFERENCES places (id)
);
