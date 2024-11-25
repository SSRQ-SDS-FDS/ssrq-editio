CREATE TABLE IF NOT EXISTS kanton_images
(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    filename TEXT NOT NULL,
    kanton_id INTEGER NOT NULL,
    FOREIGN KEY (kanton_id) REFERENCES kantons (id)
);

CREATE INDEX idx_kanton_images_kanton_id ON kanton_images (kanton_id);
