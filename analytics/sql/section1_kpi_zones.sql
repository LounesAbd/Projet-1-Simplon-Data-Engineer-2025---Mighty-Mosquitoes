-- SECTION 1 : CONNAÎTRE LES ZONES À RISQUE (VERSION AGRÉGÉE)
-- ============================================================================
-- Cette section exploite la vue matérialisée `analytics.accident_usagers_aggr`
-- ainsi que les tables de dimensions définies dans `setup_dimensions.sql`.
-- Les requêtes brutes d'origine sont conservées pour validation dans
-- `etl/sql/legacy_section1_kpi_zones.sql`.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1 KPI PRIORITAIRE : Top 10 des régions les plus accidentogènes
-- ----------------------------------------------------------------------------

WITH stats AS (
    SELECT
        reg_code,
        reg_name,
        COUNT(*) AS nb_accidents,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(nb_indemnes) AS nb_indemnes,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_blesses_hosp) AS nb_blesses_hospitalises,
        SUM(nb_blesses_legers) AS nb_blesses_legers,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr
    WHERE reg_code IS NOT NULL
    GROUP BY reg_code, reg_name
)
SELECT
    reg_code,
    reg_name,
    nb_accidents,
    nb_personnes_impliquees,
    nb_indemnes,
    nb_tues,
    nb_blesses_hospitalises,
    nb_blesses_legers,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents, 0), 2) AS pct_accidents_mortels,
    DENSE_RANK() OVER (ORDER BY nb_accidents DESC) AS rang
FROM stats
ORDER BY nb_accidents DESC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 1.2 KPI PRIORITAIRE : Top 10 des communes les plus accidentogènes
-- ----------------------------------------------------------------------------

WITH stats AS (
    SELECT
        com_code,
        com_name,
        dep_code,
        dep_name,
        COUNT(*) AS nb_accidents,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_blesses_hosp) AS nb_blesses_hospitalises,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr
    WHERE com_code IS NOT NULL
    GROUP BY com_code, com_name, dep_code, dep_name
)
SELECT
    com_code,
    com_name,
    dep_code,
    dep_name,
    nb_accidents,
    nb_personnes_impliquees,
    nb_tues,
    nb_blesses_hospitalises,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents, 0), 2) AS pct_accidents_mortels,
    DENSE_RANK() OVER (ORDER BY nb_accidents DESC) AS rang
FROM stats
ORDER BY nb_accidents DESC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 1.3 KPI PRIORITAIRE : % accidents agglo vs non-agglo
-- ----------------------------------------------------------------------------

SELECT
    aua.agg AS code_agglo,
    COALESCE(da.libelle, 'Non renseigné') AS libelle_agglo,
    COUNT(*) AS nb_accidents,
    SUM(nb_usagers_total) AS nb_personnes_impliquees,
    SUM(nb_tues) AS nb_tues,
    SUM(nb_blesses_hosp) AS nb_blesses_hospitalises,
    SUM(nb_blesses_legers) AS nb_blesses_legers,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * SUM(nb_tues) / NULLIF(SUM(SUM(nb_tues)) OVER (), 0), 2) AS pct_tues,
    ROUND(100.0 * SUM(nb_tues) / NULLIF(SUM(nb_usagers_total), 0), 2) AS taux_mortalite_pct
FROM analytics.accident_usagers_aggr aua
LEFT JOIN analytics.dim_agg da ON da.agg = aua.agg
GROUP BY aua.agg, da.libelle
ORDER BY code_agglo;

-- ----------------------------------------------------------------------------
-- 1.4 KPI PRIORITAIRE : Top des types de routes les plus accidentogènes
-- ----------------------------------------------------------------------------

WITH stats AS (
    SELECT
        COALESCE(dc.libelle, 'Non renseigné') AS libelle_categorie_route,
        catr AS code_categorie_route,
        COUNT(*) AS nb_accidents,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_blesses_hosp) AS nb_blesses_hospitalises,
        SUM(nb_blesses_legers) AS nb_blesses_legers
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_catr dc ON dc.catr = aua.catr
    GROUP BY catr, dc.libelle
)
SELECT
    code_categorie_route,
    libelle_categorie_route,
    nb_accidents,
    nb_personnes_impliquees,
    nb_tues,
    nb_blesses_hospitalises,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    DENSE_RANK() OVER (ORDER BY nb_accidents DESC) AS rang
FROM stats
ORDER BY nb_accidents DESC;

-- ----------------------------------------------------------------------------
-- 1.5 KPI PRIORITAIRE : Top des typologies de voies accidentogènes
-- ----------------------------------------------------------------------------

-- 1.5.1 Par régime de circulation
WITH stats AS (
    SELECT
        aua.circ AS regime_circulation,
        COALESCE(dc.libelle, 'Non renseigné') AS libelle_circulation,
        COUNT(*) AS nb_accidents,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_usagers_total) AS nb_personnes_impliquees
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_circ dc ON dc.circ = aua.circ
    GROUP BY aua.circ, dc.libelle
)
SELECT
    regime_circulation,
    libelle_circulation,
    nb_accidents,
    nb_tues,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct
FROM stats
ORDER BY nb_accidents DESC;

-- 1.5.2 Par voie réservée
WITH stats AS (
    SELECT
        aua.vosp AS voie_reservee,
        CASE aua.vosp
            WHEN 1 THEN 'Piste cyclable'
            WHEN 2 THEN 'Bande cyclable'
            WHEN 3 THEN 'Voie réservée'
            WHEN 4 THEN 'Voie spéciale (autre)'
            WHEN 5 THEN 'Voie spéciale (non précisée)'
            ELSE 'Pas de voie réservée'
        END AS libelle_voie_reservee,
        COUNT(*) AS nb_accidents,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_usagers_total) AS nb_personnes_impliquees
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.vosp
)
SELECT
    voie_reservee,
    libelle_voie_reservee,
    nb_accidents,
    nb_tues,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct
FROM stats
ORDER BY nb_accidents DESC;

-- 1.5.3 Par tracé en plan
WITH stats AS (
    SELECT
        aua.plan AS code_trace_plan,
        CASE aua.plan
            WHEN 1 THEN 'Partie rectiligne'
            WHEN 2 THEN 'En courbe à gauche'
            WHEN 3 THEN 'En courbe à droite'
            WHEN 4 THEN 'En S'
            ELSE 'Non renseigné'
        END AS libelle_trace_plan,
        COUNT(*) AS nb_accidents,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_usagers_total) AS nb_personnes_impliquees
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.plan
)
SELECT
    code_trace_plan,
    libelle_trace_plan,
    nb_accidents,
    nb_tues,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct
FROM stats
ORDER BY nb_accidents DESC;

-- 1.5.4 Par profil en plan (déclivité)
WITH stats AS (
    SELECT
        aua.prof AS code_profil,
        CASE aua.prof
            WHEN 1 THEN 'Plat'
            WHEN 2 THEN 'Pente'
            WHEN 3 THEN 'Sommet de côte'
            WHEN 4 THEN 'Bas de côte'
            ELSE 'Non renseigné'
        END AS libelle_profil,
        COUNT(*) AS nb_accidents,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_usagers_total) AS nb_personnes_impliquees
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.prof
)
SELECT
    code_profil,
    libelle_profil,
    nb_accidents,
    nb_tues,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct
FROM stats
ORDER BY nb_accidents DESC;

-- ----------------------------------------------------------------------------
-- 1.6 KPI SECONDAIRE : Top 10 des régions avec le plus d'accidents mortels
-- ----------------------------------------------------------------------------

WITH stats AS (
    SELECT
        reg_code,
        reg_name,
        COUNT(*) AS nb_accidents_total,
        SUM(nb_tues) AS nb_tues,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels,
        SUM(nb_usagers_total) AS nb_personnes_impliquees
    FROM analytics.accident_usagers_aggr
    WHERE reg_code IS NOT NULL
    GROUP BY reg_code, reg_name
)
SELECT
    reg_code,
    reg_name,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents_total,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents_total, 0), 2) AS pct_accidents_mortels,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    DENSE_RANK() OVER (ORDER BY nb_tues DESC) AS rang
FROM stats
ORDER BY nb_tues DESC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 1.7 KPI SECONDAIRE : Top 10 des communes avec le plus d'accidents mortels
-- ----------------------------------------------------------------------------

WITH stats AS (
    SELECT
        com_code,
        com_name,
        dep_code,
        dep_name,
        COUNT(*) AS nb_accidents_total,
        SUM(nb_tues) AS nb_tues,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels,
        SUM(nb_usagers_total) AS nb_personnes_impliquees
    FROM analytics.accident_usagers_aggr
    WHERE com_code IS NOT NULL
    GROUP BY com_code, com_name, dep_code, dep_name
)
SELECT
    com_code,
    com_name,
    dep_code,
    dep_name,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents_total,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents_total, 0), 2) AS pct_accidents_mortels,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    DENSE_RANK() OVER (ORDER BY nb_tues DESC) AS rang
FROM stats
ORDER BY nb_tues DESC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 1.8 KPI SECONDAIRE : % d'accidents mortels agglo VS non-agglo
-- ----------------------------------------------------------------------------

SELECT
    aua.agg AS code_agglo,
    COALESCE(da.libelle, 'Non renseigné') AS libelle_agglo,
    SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels,
    SUM(nb_tues) AS nb_tues,
    COUNT(*) AS nb_accidents_total,
    ROUND(100.0 * SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) /
          NULLIF(SUM(SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END)) OVER (), 0), 2) AS pct_accidents_mortels,
    ROUND(100.0 * SUM(nb_tues) / NULLIF(SUM(SUM(nb_tues)) OVER (), 0), 2) AS pct_tues,
    ROUND(100.0 * SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(*), 0), 2) AS taux_accidents_mortels_pct
FROM analytics.accident_usagers_aggr aua
LEFT JOIN analytics.dim_agg da ON da.agg = aua.agg
GROUP BY aua.agg, da.libelle
ORDER BY code_agglo;

-- ----------------------------------------------------------------------------
-- 1.9 KPI SECONDAIRE : Top des types de routes les plus mortelles
-- ----------------------------------------------------------------------------

WITH stats AS (
    SELECT
        aua.catr AS code_categorie_route,
        COALESCE(dc.libelle, 'Non renseigné') AS libelle_categorie_route,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels,
        SUM(nb_tues) AS nb_tues,
        COUNT(*) AS nb_accidents_total
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_catr dc ON dc.catr = aua.catr
    GROUP BY aua.catr, dc.libelle
)
SELECT
    code_categorie_route,
    libelle_categorie_route,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents_total,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(SUM(nb_accidents_mortels) OVER (), 0), 2) AS pct_accidents_mortels,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents_total, 0), 2) AS taux_accidents_mortels_pct,
    DENSE_RANK() OVER (ORDER BY nb_tues DESC) AS rang
FROM stats
ORDER BY nb_tues DESC;

-- ----------------------------------------------------------------------------
-- 1.10 KPI SECONDAIRE : Top des typologies de voies les plus mortelles
-- ----------------------------------------------------------------------------

-- 1.10.1 Par régime de circulation (mortels)
WITH stats AS (
    SELECT
        aua.circ AS code_circulation,
        COALESCE(dc.libelle, 'Non renseigné') AS libelle_circulation,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels,
        SUM(nb_tues) AS nb_tues
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_circ dc ON dc.circ = aua.circ
    GROUP BY aua.circ, dc.libelle
)
SELECT
    code_circulation,
    libelle_circulation,
    nb_accidents_mortels,
    nb_tues,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(SUM(nb_accidents_mortels) OVER (), 0), 2) AS pct_accidents_mortels
FROM stats
ORDER BY nb_tues DESC;

-- 1.10.2 Par tracé en plan (mortels)
WITH stats AS (
    SELECT
        aua.plan AS code_trace_plan,
        CASE aua.plan
            WHEN 1 THEN 'Partie rectiligne'
            WHEN 2 THEN 'En courbe à gauche'
            WHEN 3 THEN 'En courbe à droite'
            WHEN 4 THEN 'En S'
            ELSE 'Non renseigné'
        END AS libelle_trace_plan,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels,
        SUM(nb_tues) AS nb_tues
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.plan
)
SELECT
    code_trace_plan,
    libelle_trace_plan,
    nb_accidents_mortels,
    nb_tues,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(SUM(nb_accidents_mortels) OVER (), 0), 2) AS pct_accidents_mortels
FROM stats
ORDER BY nb_tues DESC;

-- ============================================================================
