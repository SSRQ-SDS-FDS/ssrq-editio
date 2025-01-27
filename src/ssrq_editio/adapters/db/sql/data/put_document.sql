INSERT OR REPLACE INTO documents (
    uuid,
    idno,
    is_main,
    sort_key,
    de_orig_date,
    en_orig_date,
    fr_orig_date,
    it_orig_date,
    facs,
    printed_idno,
    volume_id,
    orig_place,
    de_title,
    fr_title,
    entities
) VALUES (
    :uuid,
    :idno,
    :is_main,
    :sort_key,
    :de_orig_date,
    :en_orig_date,
    :fr_orig_date,
    :it_orig_date,
    CASE
        WHEN typeof(:facs) = 'text' AND :facs IS NOT NULL THEN json(:facs)
        ELSE :facs
    END,
    :printed_idno,
    :volume_id,
    :orig_place,
    :de_title,
    :fr_title,
    CASE
        WHEN
            typeof(:entities) = 'text' AND :entities IS NOT NULL
            THEN json(:facs)
        ELSE :entities
    END
);
