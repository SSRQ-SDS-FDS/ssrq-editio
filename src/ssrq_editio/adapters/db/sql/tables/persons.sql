CREATE TABLE IF NOT EXISTS persons
(
    id TEXT NOT NULL PRIMARY KEY,
    de_name TEXT NULL,
    fr_name TEXT NULL,
    it_name TEXT NULL,
    lt_name TEXT NULL,
    rm_name TEXT NULL,
    de_surname TEXT NULL,
    fr_surname TEXT NULL,
    it_surname TEXT NULL,
    lt_surname TEXT NULL,
    rm_surname TEXT NULL,
    sex TEXT NOT NULL,
    first_mention TEXT NULL,
    last_mention TEXT NULL,
    birth TEXT NULL,
    death TEXT NULL
);

CREATE VIRTUAL TABLE IF NOT EXISTS persons_fts USING fts5( -- noqa: PRS
    id UNINDEXED,
    de_name,
    fr_name,
    it_name,
    lt_name,
    rm_name,
    de_surname,
    fr_surname,
    it_surname,
    lt_surname,
    rm_surname
);

CREATE TRIGGER IF NOT EXISTS persons_ai AFTER INSERT ON persons BEGIN
    INSERT INTO persons_fts (
        rowid,
        id,
        de_name,
        fr_name,
        it_name,
        lt_name,
        rm_name,
        de_surname,
        fr_surname,
        it_surname,
        lt_surname,
        rm_surname
    ) VALUES (
        new.rowid,
        new.id,
        new.de_name,
        new.fr_name,
        new.it_name,
        new.lt_name,
        new.rm_name,
        new.de_surname,
        new.fr_surname,
        new.it_surname,
        new.lt_surname,
        new.rm_surname
    );
END;

CREATE TRIGGER IF NOT EXISTS persons_au AFTER UPDATE ON persons BEGIN
    UPDATE persons_fts SET
        id = new.id,
        de_name = new.de_name,
        fr_name = new.fr_name,
        it_name = new.it_name,
        lt_name = new.lt_name,
        rm_name = new.rm_name,
        de_surname = new.de_surname,
        fr_surname = new.fr_surname,
        it_surname = new.it_surname,
        lt_surname = new.lt_surname,
        rm_surname = new.rm_surname
    WHERE id = old.id;
END;

CREATE TRIGGER IF NOT EXISTS persons_ad AFTER DELETE ON persons BEGIN
    DELETE FROM persons_fts WHERE id = old.id;
END;
