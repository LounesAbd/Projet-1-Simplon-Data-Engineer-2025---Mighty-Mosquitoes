-- BONUS : REQUÊTES UTILES POUR L'ANALYSE
-- ============================================================================

-- ----------------------------------------------------------------------------

-- Vue d'ensemble rapide du dataset
-- ----------------------------------------------------------------------------

SELECT
    'Période couverte' as metrique,
    MIN(make_date(d.an, d.mois, d.jour))::TEXT || ' - ' || MAX(make_date(d.an, d.mois, d.jour))::TEXT as valeur
FROM DATE_ACCIDENT d
WHERE d.an IS NOT NULL AND d.mois IS NOT NULL AND d.jour IS NOT NULL
UNION ALL
SELECT
    'Nombre total d''accidents',
    COUNT(DISTINCT num_acc)::TEXT
FROM ACCIDENT
UNION ALL
SELECT
    'Nombre total de personnes impliquées',
    COUNT(*)::TEXT
FROM USAGER
UNION ALL
SELECT
    'Nombre total de véhicules impliqués',
    COUNT(*)::TEXT
FROM VEHICULE
UNION ALL
SELECT
    'Nombre total de tués',
    SUM(CASE WHEN grav = 2 THEN 1 ELSE 0 END)::TEXT
FROM USAGER
UNION ALL
SELECT
    'Nombre total de blessés hospitalisés',
    SUM(CASE WHEN grav = 3 THEN 1 ELSE 0 END)::TEXT
FROM USAGER
UNION ALL
SELECT
    'Nombre de régions concernées',
    COUNT(DISTINCT reg_code)::TEXT
FROM LIEUX
WHERE reg_code IS NOT NULL
UNION ALL
SELECT
    'Nombre de départements concernés',
    COUNT(DISTINCT dep_code)::TEXT
FROM LIEUX
WHERE dep_code IS NOT NULL
UNION ALL
SELECT
    'Nombre de communes concernées',
    COUNT(DISTINCT com_code)::TEXT
FROM LIEUX
WHERE com_code IS NOT NULL;

-- ----------------------------------------------------------------------------

-- Répartition par gravité des usagers
-- ----------------------------------------------------------------------------

SELECT
    grav as code_gravite,
    CASE grav
        WHEN 1 THEN 'Indemne'
        WHEN 2 THEN 'Tué'
        WHEN 3 THEN 'Blessé hospitalisé'
        WHEN 4 THEN 'Blessé léger'
        ELSE 'Non renseigné'
    END as libelle_gravite,
    COUNT(*) as nombre,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pourcentage
FROM USAGER
GROUP BY grav
ORDER BY grav;

-- ============================================================================
-- Fin du fichier requetes.sql
-- ============================================================================
