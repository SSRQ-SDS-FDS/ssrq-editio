CREATE TABLE IF NOT EXISTS persons_terms
(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    term_id TEXT NOT NULL,
    person_id TEXT NOT NULL,
    FOREIGN KEY (term_id) REFERENCES terms (id),
    FOREIGN KEY (person_id) REFERENCES persons (id)
);
