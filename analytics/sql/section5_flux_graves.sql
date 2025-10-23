-- SECTION 5 : ZONES FRÉQUENTÉES vs ACCIDENTS GRAVES (VERSION AGRÉGÉE)
-- =========================================================================
-- Les analyses s'appuient sur la vue `analytics.accident_usagers_aggr` afin de
-- comparer volume et gravité sans recalculer les jointures. Les requêtes
-- d'origine sont conservées dans `etl/sql/legacy_section5_flux_graves.sql`.
-- =========================================================================

-- ----------------------------------------------------------------------------
-- 5.1 Analyse par département (volume vs gravité)
-- ----------------------------------------------------------------------------
WITH stats_departements AS (
    SELECT
        dep_code AS departement,
        dep_name AS nom_departement,
        COUNT(*) AS nb_accidents,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_blesses_hosp) AS nb_blesses_hospitalises,
        SUM(nb_blesses_legers) AS nb_blesses_legers,
        SUM(100 * nb_tues + 10 * nb_blesses_hosp + nb_blesses_legers)::NUMERIC AS somme_scores,
        SUM(CASE WHEN nb_tues > 0 OR nb_blesses_hosp > 0 THEN 1 ELSE 0 END) AS nb_accidents_graves,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr
    WHERE dep_code IS NOT NULL
    GROUP BY dep_code, dep_name
),
classements AS (
    SELECT
        sd.*,
        DENSE_RANK() OVER (ORDER BY sd.nb_accidents DESC) AS rang_volume,
        DENSE_RANK() OVER (ORDER BY (sd.somme_scores / NULLIF(sd.nb_personnes_impliquees, 0)) DESC) AS rang_gravite
    FROM stats_departements sd
)
SELECT
    departement,
    nom_departement,
    nb_accidents,
    rang_volume,
    ROUND(somme_scores / NULLIF(nb_personnes_impliquees, 0), 2) AS gravite_moyenne,
    rang_gravite,
    ROUND(100.0 * nb_accidents_graves / NULLIF(nb_accidents, 0), 2) AS taux_accidents_graves,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite,
    nb_tues,
    nb_blesses_hospitalises,
    CASE
        WHEN rang_volume <= 10 AND rang_gravite <= 10 THEN 'Zone dense ET dangereuse'
        WHEN rang_volume <= 10 AND rang_gravite > 50 THEN 'Zone dense mais PEU dangereuse'
        WHEN rang_volume > 50 AND rang_gravite <= 10 THEN 'Zone peu dense mais TRÈS dangereuse'
        ELSE 'Zone moyenne'
    END AS profil_zone
FROM classements
ORDER BY nb_accidents DESC
LIMIT 50;

-- ----------------------------------------------------------------------------
-- 5.2 Corrélation volume vs gravité (coefficient de Pearson)
-- ----------------------------------------------------------------------------
WITH stats_par_dept AS (
    SELECT
        dep_code AS departement,
        COUNT(*) AS nb_accidents,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(100 * nb_tues + 10 * nb_blesses_hosp + nb_blesses_legers)::NUMERIC AS somme_scores
    FROM analytics.accident_usagers_aggr
    WHERE dep_code IS NOT NULL
    GROUP BY dep_code
),
valeurs AS (
    SELECT
        departement,
        nb_accidents::NUMERIC AS nb_accidents,
        CASE
            WHEN nb_personnes_impliquees = 0 THEN NULL
            ELSE somme_scores / nb_personnes_impliquees
        END AS gravite_moyenne
    FROM stats_par_dept
)
SELECT
    ROUND(CORR(nb_accidents, gravite_moyenne)::NUMERIC, 3) AS correlation_volume_gravite,
    CASE
        WHEN ABS(CORR(nb_accidents, gravite_moyenne)) < 0.3 THEN 'Corrélation FAIBLE : le volume n''explique pas la gravité'
        WHEN ABS(CORR(nb_accidents, gravite_moyenne)) < 0.7 THEN 'Corrélation MODÉRÉE'
        ELSE 'Corrélation FORTE : le volume d''accidents explique la gravité'
    END AS interpretation
FROM valeurs;

-- ----------------------------------------------------------------------------
-- 5.3 Top 10 départements les plus fréquentés vs plus dangereux
-- ----------------------------------------------------------------------------
(
    SELECT
        'TOP VOLUME' AS categorie,
        dep_code AS departement,
        dep_name AS nom_departement,
        COUNT(*) AS nb_accidents,
        ROUND(SUM(100 * nb_tues + 10 * nb_blesses_hosp + nb_blesses_legers)::NUMERIC /
              NULLIF(SUM(nb_usagers_total), 0), 2) AS gravite_moyenne
    FROM analytics.accident_usagers_aggr
    WHERE dep_code IS NOT NULL
    GROUP BY dep_code, dep_name
    ORDER BY nb_accidents DESC
    LIMIT 10
)
UNION ALL
(
    SELECT
        'TOP GRAVITÉ' AS categorie,
        dep_code AS departement,
        dep_name AS nom_departement,
        COUNT(*) AS nb_accidents,
        ROUND(SUM(100 * nb_tues + 10 * nb_blesses_hosp + nb_blesses_legers)::NUMERIC /
              NULLIF(SUM(nb_usagers_total), 0), 2) AS gravite_moyenne
    FROM analytics.accident_usagers_aggr
    WHERE dep_code IS NOT NULL
    GROUP BY dep_code, dep_name
    HAVING COUNT(*) >= 100
    ORDER BY gravite_moyenne DESC
    LIMIT 10
)
ORDER BY categorie, nb_accidents DESC;

-- =========================================================================
