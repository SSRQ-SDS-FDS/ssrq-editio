SELECT * FROM terms -- noqa: AM04
WHERE
    id LIKE '%' || :search || '%'
    OR de_name LIKE '%' || :search || '%'
    OR fr_name LIKE '%' || :search || '%'
    OR it_name LIKE '%' || :search || '%'
    OR lt_name LIKE '%' || :search || '%'
    OR rm_name LIKE '%' || :search || '%'
