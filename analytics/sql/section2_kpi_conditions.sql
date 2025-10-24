-- SECTION 2 : ÉTUDIER LES CONDITIONS DE SURVENUE (VERSION AGRÉGÉE)
-- ============================================================================
-- Cette section repose principalement sur la vue matérialisée
-- `analytics.accident_usagers_aggr` et les tables de dimensions créées dans
-- `setup_dimensions.sql`. Les requêtes brutes originales restent disponibles
-- pour vérification dans `etl/sql/legacy_section2_kpi_conditions.sql`.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 KPI PRIORITAIRE : Top des conditions météo les plus accidentogènes
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.atm AS code_meteo,
        COUNT(*) AS nb_accidents,
        SUM(aua.nb_usagers_total) AS nb_personnes_impliquees,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(aua.nb_blesses) AS nb_blesses
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.atm
)
SELECT
    code_meteo,
    nb_accidents,
    nb_personnes_impliquees,
    nb_tues,
    nb_blesses,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    DENSE_RANK() OVER (ORDER BY nb_accidents DESC) AS rang
FROM stats
ORDER BY nb_accidents DESC;

-- ----------------------------------------------------------------------------
-- 2.2 KPI PRIORITAIRE : Top des conditions de voirie les plus accidentogènes
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.surf AS code_surface,
        COUNT(*) AS nb_accidents,
        SUM(aua.nb_usagers_total) AS nb_personnes_impliquees,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(aua.nb_blesses) AS nb_blesses
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.surf
)
SELECT
    code_surface,
    nb_accidents,
    nb_personnes_impliquees,
    nb_tues,
    nb_blesses,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    DENSE_RANK() OVER (ORDER BY nb_accidents DESC) AS rang
FROM stats
ORDER BY nb_accidents DESC;

-- ----------------------------------------------------------------------------
-- 2.3 KPI PRIORITAIRE : Top des conditions de luminosité les plus accidentogènes
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.lum AS code_lumiere,
        COUNT(*) AS nb_accidents,
        SUM(aua.nb_usagers_total) AS nb_personnes_impliquees,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(aua.nb_blesses) AS nb_blesses
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.lum
)
SELECT
    code_lumiere,
    nb_accidents,
    nb_personnes_impliquees,
    nb_tues,
    nb_blesses,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    DENSE_RANK() OVER (ORDER BY nb_accidents DESC) AS rang
FROM stats
ORDER BY nb_accidents DESC;

-- ----------------------------------------------------------------------------
-- 2.4 KPI PRIORITAIRE : Répartition des accidents par type de collision
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.code_collision,
        COUNT(*) AS nb_accidents,
        SUM(aua.nb_usagers_total) AS nb_personnes_impliquees,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(aua.nb_blesses) AS nb_blesses
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.code_collision
)
SELECT
    code_collision,
    nb_accidents,
    nb_personnes_impliquees,
    nb_tues,
    nb_blesses,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    DENSE_RANK() OVER (ORDER BY nb_accidents DESC) AS rang
FROM stats
ORDER BY nb_accidents DESC;

-- ----------------------------------------------------------------------------
-- 2.5 KPI PRIORITAIRE : Répartition des accidents par type de véhicule
-- ----------------------------------------------------------------------------
WITH vehicules AS (
    SELECT
        v.num_acc,
        v.catv,
        COUNT(*) AS nb_vehicules_cat_acc
    FROM VEHICULE v
    GROUP BY v.num_acc, v.catv
),
stats AS (
    SELECT
        v.catv AS code_categorie_vehicule,
        SUM(v.nb_vehicules_cat_acc) AS nb_vehicules,
        COUNT(*) AS nb_accidents,
        SUM(aua.nb_usagers_total) AS nb_personnes_impliquees,
        SUM(aua.nb_tues) AS nb_tues
    FROM vehicules v
    INNER JOIN analytics.accident_usagers_aggr aua USING (num_acc)
    GROUP BY v.catv
)
SELECT
    code_categorie_vehicule,
    nb_vehicules,
    nb_accidents,
    nb_personnes_impliquees,
    nb_tues,
    ROUND(100.0 * nb_vehicules / NULLIF(SUM(nb_vehicules) OVER (), 0), 2) AS pct_vehicules,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents
FROM stats
ORDER BY nb_vehicules DESC;

-- ----------------------------------------------------------------------------
-- 2.6 KPI PRIORITAIRE : Répartition des accidents par type d'usagers
-- ----------------------------------------------------------------------------
WITH usagers AS (
    SELECT
        u.num_acc,
        u.catu,
        COUNT(*) AS nb_personnes,
        SUM(CASE WHEN u.grav = 'Indemne' THEN 1 ELSE 0 END) AS nb_indemnes,
        SUM(CASE WHEN u.grav = 'Tué' THEN 1 ELSE 0 END) AS nb_tues,
        SUM(CASE WHEN u.grav = 'Blessé' THEN 1 ELSE 0 END) AS nb_blesses
        FROM USAGER u
    GROUP BY u.num_acc, u.catu
),
stats AS (
    SELECT
        u.catu AS code_categorie_usager,
        SUM(u.nb_personnes) AS nb_personnes,
        SUM(u.nb_indemnes) AS nb_indemnes,
        SUM(u.nb_tues) AS nb_tues,
        SUM(u.nb_blesses) AS nb_blesses,
        COUNT(*) AS nb_accidents
    FROM usagers u
    GROUP BY u.catu
)
SELECT
    code_categorie_usager,
    nb_personnes,
    nb_accidents,
    nb_indemnes,
    nb_tues,
    nb_blesses,
    ROUND(100.0 * nb_personnes / NULLIF(SUM(nb_personnes) OVER (), 0), 2) AS pct_usagers,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes, 0), 2) AS taux_mortalite_pct,
    DENSE_RANK() OVER (ORDER BY nb_personnes DESC) AS rang
FROM stats
ORDER BY nb_personnes DESC;

-- ----------------------------------------------------------------------------
-- 2.7 KPI SECONDAIRE : Top des conditions météo les plus mortelles
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.atm AS code_meteo,
        COUNT(*) AS nb_accidents_total,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(CASE WHEN aua.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.atm
)
SELECT
    code_meteo,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents_total,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(SUM(nb_accidents_mortels) OVER (), 0), 2) AS pct_accidents_mortels,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents_total, 0), 2) AS taux_accidents_mortels_pct
FROM stats
ORDER BY nb_tues DESC;

-- ----------------------------------------------------------------------------
-- 2.8 KPI SECONDAIRE : Top des conditions de voirie les plus mortelles
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.surf AS code_surface,
        COUNT(*) AS nb_accidents_total,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(CASE WHEN aua.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.surf
)
SELECT
    code_surface,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents_total,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(SUM(nb_accidents_mortels) OVER (), 0), 2) AS pct_accidents_mortels,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents_total, 0), 2) AS taux_accidents_mortels_pct
FROM stats
ORDER BY nb_tues DESC;

-- ----------------------------------------------------------------------------
-- 2.9 KPI SECONDAIRE : Top des conditions de luminosité les plus mortelles
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.lum AS code_lumiere,
        COUNT(*) AS nb_accidents_total,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(CASE WHEN aua.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.lum
)
SELECT
    code_lumiere,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents_total,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(SUM(nb_accidents_mortels) OVER (), 0), 2) AS pct_accidents_mortels,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents_total, 0), 2) AS taux_accidents_mortels_pct
FROM stats
ORDER BY nb_tues DESC;

-- ----------------------------------------------------------------------------
-- 2.10 KPI SECONDAIRE : Types de collision les plus mortelles
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.code_collision,
        COUNT(*) AS nb_accidents_total,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(CASE WHEN aua.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.code_collision
)
SELECT
    code_collision,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents_total,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(SUM(nb_accidents_mortels) OVER (), 0), 2) AS pct_accidents_mortels,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents_total, 0), 2) AS taux_accidents_mortels_pct
FROM stats
ORDER BY nb_tues DESC;

-- ----------------------------------------------------------------------------
-- 2.11 KPI SECONDAIRE : Répartition des accidents mortels par type de véhicule
-- ----------------------------------------------------------------------------
WITH vehicules AS (
    SELECT
        v.num_acc,
        v.catv,
        COUNT(*) AS nb_vehicules_cat_acc
    FROM VEHICULE v
    GROUP BY v.num_acc, v.catv
),
stats AS (
    SELECT
        v.catv AS code_categorie_vehicule,
        SUM(v.nb_vehicules_cat_acc) AS nb_vehicules,
        COUNT(*) AS nb_accidents,
        SUM(CASE WHEN aua.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels,
        SUM(aua.nb_tues) AS nb_tues
    FROM vehicules v
    INNER JOIN analytics.accident_usagers_aggr aua USING (num_acc)
    GROUP BY v.catv
)
SELECT
    code_categorie_vehicule,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(SUM(nb_accidents_mortels) OVER (), 0), 2) AS pct_accidents_mortels
FROM stats
ORDER BY nb_tues DESC;

-- ----------------------------------------------------------------------------
-- 2.12 KPI SECONDAIRE : Répartition des accidents mortels par type d'usagers
-- ----------------------------------------------------------------------------
WITH usagers AS (
    SELECT
        u.num_acc,
        u.catu,
        COUNT(*) AS nb_personnes,
        SUM(CASE WHEN u.grav = 'Tué' THEN 1 ELSE 0 END) AS nb_tues
    FROM USAGER u
    GROUP BY u.num_acc, u.catu
),
stats AS (
    SELECT
        u.catu AS code_categorie_usager,
        SUM(u.nb_personnes) AS nb_personnes_total,
        SUM(u.nb_tues) AS nb_tues,
        SUM(CASE WHEN u.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM usagers u
    GROUP BY u.catu
)
SELECT
    code_categorie_usager,
    nb_tues,
    nb_personnes_total,
    nb_accidents_mortels,
    ROUND(100.0 * nb_tues / NULLIF(SUM(nb_tues) OVER (), 0), 2) AS pct_tues,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_total, 0), 2) AS taux_mortalite_pct
FROM stats
ORDER BY nb_tues DESC;

-- ============================================================================
