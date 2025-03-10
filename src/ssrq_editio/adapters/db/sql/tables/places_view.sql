DROP VIEW IF EXISTS places_view;
CREATE VIEW places_view AS
SELECT
    places.id,
    places.cs_name,
    places.de_name,
    places.fr_name,
    places.it_name,
    places.lt_name,
    places.nl_name,
    places.pl_name,
    places.rm_name,
    places.de_place_types,
    places.fr_place_types,
    occurrences.occurrences,
    occurrences.printed_idno
FROM places
LEFT JOIN
        ( SELECT occurrences.ref, GROUP_CONCAT(occurrences.uuid, ',') AS occurrences,
        (SELECT GROUP_CONCAT(documents.printed_idno) FROM documents WHERE documents.uuid = occurrences.uuid) AS printed_idno FROM occurrences GROUP BY occurrences.ref) AS occurrences
    ON places.id = occurrences.ref
;
