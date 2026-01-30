WITH documents_in_volume AS (
    SELECT
        *,
        LAG(idno) OVER (
            ORDER BY sort_key
        ) AS previous_document,
        LEAD(idno) OVER (
            ORDER BY sort_key
        ) AS next_document
    FROM documents
    WHERE
        volume_id = (
            SELECT vol_id_d.volume_id
            FROM documents AS vol_id_d
            WHERE vol_id_d.idno LIKE '%' || :idno OR vol_id_d.uuid = :idno
        )
)

SELECT
    uuid,
    idno,
    is_main,
    sort_key,
    de_orig_date,
    en_orig_date,
    fr_orig_date,
    it_orig_date,
    facs,
    facs_responsible,
    printed_idno,
    volume_id,
    orig_place,
    de_title,
    fr_title,
    entities,
    source,
    type,
    start_year_of_creation,
    end_year_of_creation,
    previous_document,
    next_document
FROM documents_in_volume
WHERE idno LIKE '%' || :idno OR uuid = :idno;
