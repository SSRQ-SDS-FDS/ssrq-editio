SELECT * FROM places -- noqa: AM04
WHERE
    id LIKE '%' || :search || '%'
    OR cs_name LIKE '%' || :search || '%'
    OR de_name LIKE '%' || :search || '%'
    OR fr_name LIKE '%' || :search || '%'
    OR it_name LIKE '%' || :search || '%'
    OR lt_name LIKE '%' || :search || '%'
    OR nl_name LIKE '%' || :search || '%'
    OR pl_name LIKE '%' || :search || '%'
    OR rm_name LIKE '%' || :search || '%'
