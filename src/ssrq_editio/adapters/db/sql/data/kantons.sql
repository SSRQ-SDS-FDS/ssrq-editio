-- We can hardcode the values for the kantons table,
-- as they are not expected to change.
INSERT INTO kantons (id, short_name, de_title, fr_title, it_title) VALUES
(1, 'ZH', 'I. Abteilung: Die Rechtsquellen des Kantons Zürich', NULL, NULL),
(2, 'BE', 'II. Abteilung: Die Rechtsquellen des Kantons Bern', NULL, NULL),
(3, 'LU', 'III. Abteilung: Die Rechtsquellen des Kantons Luzern', NULL, NULL),
(4, 'UR', 'IV. Abteilung: Die Rechtsquellen des Kantons Uri', NULL, NULL),
(5, 'SZ', 'V. Abteilung: Die Rechtsquellen des Kantons Schwyz', NULL, NULL),
(
    6,
    'OW/NW',
    'VI. Abteilung: Die Rechtsquellen des Kantons Unterwalden',
    NULL,
    NULL
),
(7, 'GL', 'VII. Abteilung: Die Rechtsquellen des Kantons Glarus', NULL, NULL),
(8, 'ZG', 'VIII. Abteilung: Die Rechtsquellen des Kantons Zug', NULL, NULL),
(
    9,
    'FR',
    'IX. Abteilung: Die Rechtsquellen des Kantons Freiburg',
    'IX. partie : Les sources du droit du canton de Fribourg',
    'IX sezione: Le fonti del diritto del cantone di Friburgo'
),
(10, 'SO', 'X. Abteilung: Die Rechtsquellen des Kantons Solothurn', NULL, NULL),
(11, 'BS/BL', 'XI. Abteilung: Die Rechtsquellen der Kantone Basel', NULL, NULL),
(
    12,
    'SH',
    'XII. Abteilung: Die Rechtsquellen des Kantons Schaffhausen',
    NULL,
    NULL
),
(
    13,
    'AR/AI',
    'XIII. Abteilung: Die Rechtsquellen der Kantone Appenzell',
    NULL,
    NULL
),
(
    14,
    'SG',
    'XIV. Abteilung: Die Rechtsquellen des Kantons St. Gallen',
    NULL,
    NULL
),
(
    15,
    'GR',
    'XV. Abteilung: Die Rechtsquellen des Kantons Graubünden',
    'XV. partiziun: Las funtaunas da dretg dal chantun Grischun',
    'XV sezione: Le fonti del diritto del cantone dei Grigioni'
),
(16, 'AG', 'XVI. Abteilung: Die Rechtsquellen des Kantons Aargau', NULL, NULL),
(
    17,
    'TG',
    'XVII. Abteilung: Die Rechtsquellen des Kantons Thurgau',
    NULL,
    NULL
),
(
    18,
    'TI',
    'XVIII sezione: Le fonti del diritto del cantone Ticino',
    NULL,
    NULL
),
(19, 'VD', 'XIX. partie : Les sources du droit du canton de Vaud', NULL, NULL),
(
    20,
    'VS',
    'XX. partie : Les sources du droit du canton du Valais',
    'XX. Abteilung: Die Rechtsquellen des Kantons Wallis',
    NULL
),
(
    21,
    'NE',
    'XXI. partie : Les sources du droit du canton de Neuchâtel',
    NULL,
    NULL
),
(
    22,
    'GE',
    'XXII. partie : Les sources du droit du canton de Genève',
    NULL,
    NULL
),
(
    23,
    'JU',
    'XXIII. partie : Les sources du droit du canton du Jura',
    NULL,
    NULL
);
