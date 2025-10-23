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
        COALESCE(da.libelle, 'Non renseigné') AS libelle_meteo,
        COUNT(*) AS nb_accidents,
        SUM(aua.nb_usagers_total) AS nb_personnes_impliquees,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(aua.nb_blesses_hosp) AS nb_blesses_hospitalises
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_atm da ON da.atm = aua.atm
    GROUP BY aua.atm, da.libelle
)
SELECT
    code_meteo,
    libelle_meteo,
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
-- 2.2 KPI PRIORITAIRE : Top des conditions de voirie les plus accidentogènes
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.surf AS code_surface,
        CASE aua.surf
            WHEN 1 THEN 'Normale'
            WHEN 2 THEN 'Mouillée'
            WHEN 3 THEN 'Flaques'
            WHEN 4 THEN 'Inondée'
            WHEN 5 THEN 'Enneigée'
            WHEN 6 THEN 'Boue'
            WHEN 7 THEN 'Verglacée'
            WHEN 8 THEN 'Corps gras / huile'
            WHEN 9 THEN 'Autre'
            ELSE 'Non renseigné'
        END AS libelle_surface,
        COUNT(*) AS nb_accidents,
        SUM(aua.nb_usagers_total) AS nb_personnes_impliquees,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(aua.nb_blesses_hosp) AS nb_blesses_hospitalises
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.surf
)
SELECT
    code_surface,
    libelle_surface,
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
-- 2.3 KPI PRIORITAIRE : Top des conditions de luminosité les plus accidentogènes
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.lum AS code_lumiere,
        COALESCE(dl.libelle, 'Non renseigné') AS libelle_lumiere,
        COUNT(*) AS nb_accidents,
        SUM(aua.nb_usagers_total) AS nb_personnes_impliquees,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(aua.nb_blesses_hosp) AS nb_blesses_hospitalises
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_lum dl ON dl.lum = aua.lum
    GROUP BY aua.lum, dl.libelle
)
SELECT
    code_lumiere,
    libelle_lumiere,
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
-- 2.4 KPI PRIORITAIRE : Répartition des accidents par type de collision
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.code_collision,
        CASE aua.code_collision
            WHEN 1 THEN 'Deux véhicules - frontale'
            WHEN 2 THEN 'Deux véhicules - par l''arrière'
            WHEN 3 THEN 'Deux véhicules - par le côté'
            WHEN 4 THEN '3 véhicules et + - en chaîne'
            WHEN 5 THEN '3 véhicules et + - collisions multiples'
            WHEN 6 THEN 'Autre collision'
            WHEN 7 THEN 'Sans collision'
            ELSE 'Non renseigné'
        END AS libelle_collision,
        COUNT(*) AS nb_accidents,
        SUM(aua.nb_usagers_total) AS nb_personnes_impliquees,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(aua.nb_blesses_hosp) AS nb_blesses_hospitalises
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.code_collision
)
SELECT
    code_collision,
    libelle_collision,
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
-- 2.5 KPI PRIORITAIRE : Répartition des accidents par type de véhicule
-- ----------------------------------------------------------------------------
WITH vehicules AS (
    SELECT
        v.num_acc,
        v.catv,
        CASE
            WHEN v.catv IN (1, 2, 3, 4, 5, 6, 7) THEN 'Véhicule léger'
            WHEN v.catv IN (10, 11, 12, 13, 14, 15, 16, 17) THEN 'Véhicule utilitaire'
            WHEN v.catv IN (20, 21) THEN 'Poids lourd'
            WHEN v.catv BETWEEN 30 AND 38 THEN 'Transports en commun'
            WHEN v.catv BETWEEN 40 AND 43 THEN 'Train'
            WHEN v.catv IN (50, 60) THEN 'Deux-roues motorisé'
            WHEN v.catv BETWEEN 80 AND 83 THEN 'Vélo / Mobilité douce'
            WHEN v.catv = 99 THEN 'Autre véhicule'
            ELSE 'Non renseigné'
        END AS categorie_vehicule_groupe,
        COUNT(*) AS nb_vehicules_cat_acc
    FROM VEHICULE v
    GROUP BY v.num_acc, v.catv
),
stats AS (
    SELECT
        v.catv AS code_categorie_vehicule,
        v.categorie_vehicule_groupe,
        SUM(v.nb_vehicules_cat_acc) AS nb_vehicules,
        COUNT(*) AS nb_accidents,
        SUM(aua.nb_usagers_total) AS nb_personnes_impliquees,
        SUM(aua.nb_tues) AS nb_tues
    FROM vehicules v
    INNER JOIN analytics.accident_usagers_aggr aua USING (num_acc)
    GROUP BY v.catv, v.categorie_vehicule_groupe
)
SELECT
    code_categorie_vehicule,
    categorie_vehicule_groupe,
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
        SUM(CASE WHEN u.grav = 1 THEN 1 ELSE 0 END) AS nb_indemnes,
        SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) AS nb_tues,
        SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) AS nb_blesses_hospitalises,
        SUM(CASE WHEN u.grav = 4 THEN 1 ELSE 0 END) AS nb_blesses_legers
    FROM USAGER u
    GROUP BY u.num_acc, u.catu
),
stats AS (
    SELECT
        u.catu AS code_categorie_usager,
        CASE u.catu
            WHEN 1 THEN 'Conducteur'
            WHEN 2 THEN 'Passager'
            WHEN 3 THEN 'Piéton'
            WHEN 4 THEN 'Piéton mobilité douce'
            ELSE 'Non renseigné'
        END AS libelle_categorie_usager,
        SUM(u.nb_personnes) AS nb_personnes,
        SUM(u.nb_indemnes) AS nb_indemnes,
        SUM(u.nb_tues) AS nb_tues,
        SUM(u.nb_blesses_hospitalises) AS nb_blesses_hospitalises,
        SUM(u.nb_blesses_legers) AS nb_blesses_legers,
        COUNT(*) AS nb_accidents
    FROM usagers u
    GROUP BY u.catu
)
SELECT
    code_categorie_usager,
    libelle_categorie_usager,
    nb_personnes,
    nb_accidents,
    nb_indemnes,
    nb_tues,
    nb_blesses_hospitalises,
    nb_blesses_legers,
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
        COALESCE(da.libelle, 'Non renseigné') AS libelle_meteo,
        COUNT(*) AS nb_accidents_total,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(CASE WHEN aua.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_atm da ON da.atm = aua.atm
    GROUP BY aua.atm, da.libelle
)
SELECT
    code_meteo,
    libelle_meteo,
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
        CASE aua.surf
            WHEN 1 THEN 'Normale'
            WHEN 2 THEN 'Mouillée'
            WHEN 3 THEN 'Flaques'
            WHEN 4 THEN 'Inondée'
            WHEN 5 THEN 'Enneigée'
            WHEN 6 THEN 'Boue'
            WHEN 7 THEN 'Verglacée'
            WHEN 8 THEN 'Corps gras / huile'
            WHEN 9 THEN 'Autre'
            ELSE 'Non renseigné'
        END AS libelle_surface,
        COUNT(*) AS nb_accidents_total,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(CASE WHEN aua.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.surf
)
SELECT
    code_surface,
    libelle_surface,
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
        COALESCE(dl.libelle, 'Non renseigné') AS libelle_lumiere,
        COUNT(*) AS nb_accidents_total,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(CASE WHEN aua.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_lum dl ON dl.lum = aua.lum
    GROUP BY aua.lum, dl.libelle
)
SELECT
    code_lumiere,
    libelle_lumiere,
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
        CASE aua.code_collision
            WHEN 1 THEN 'Deux véhicules - frontale'
            WHEN 2 THEN 'Deux véhicules - par l''arrière'
            WHEN 3 THEN 'Deux véhicules - par le côté'
            WHEN 4 THEN '3 véhicules et + - en chaîne'
            WHEN 5 THEN '3 véhicules et + - collisions multiples'
            WHEN 6 THEN 'Autre collision'
            WHEN 7 THEN 'Sans collision'
            ELSE 'Non renseigné'
        END AS libelle_collision,
        COUNT(*) AS nb_accidents_total,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(CASE WHEN aua.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr aua
    GROUP BY aua.code_collision
)
SELECT
    code_collision,
    libelle_collision,
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
        CASE
            WHEN v.catv IN (1, 2, 3, 4, 5, 6, 7) THEN 'Véhicule léger'
            WHEN v.catv IN (10, 11, 12, 13, 14, 15, 16, 17) THEN 'Véhicule utilitaire'
            WHEN v.catv IN (20, 21) THEN 'Poids lourd'
            WHEN v.catv BETWEEN 30 AND 38 THEN 'Transports en commun'
            WHEN v.catv BETWEEN 40 AND 43 THEN 'Train'
            WHEN v.catv IN (50, 60) THEN 'Deux-roues motorisé'
            WHEN v.catv BETWEEN 80 AND 83 THEN 'Vélo / Mobilité douce'
            WHEN v.catv = 99 THEN 'Autre véhicule'
            ELSE 'Non renseigné'
        END AS categorie_vehicule_groupe,
        COUNT(*) AS nb_vehicules_cat_acc
    FROM VEHICULE v
    GROUP BY v.num_acc, v.catv
),
stats AS (
    SELECT
        v.catv AS code_categorie_vehicule,
        v.categorie_vehicule_groupe,
        SUM(v.nb_vehicules_cat_acc) AS nb_vehicules,
        COUNT(*) AS nb_accidents,
        SUM(CASE WHEN aua.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels,
        SUM(aua.nb_tues) AS nb_tues
    FROM vehicules v
    INNER JOIN analytics.accident_usagers_aggr aua USING (num_acc)
    GROUP BY v.catv, v.categorie_vehicule_groupe
)
SELECT
    code_categorie_vehicule,
    categorie_vehicule_groupe,
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
        SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) AS nb_tues
    FROM USAGER u
    GROUP BY u.num_acc, u.catu
),
stats AS (
    SELECT
        u.catu AS code_categorie_usager,
        CASE u.catu
            WHEN 1 THEN 'Conducteur'
            WHEN 2 THEN 'Passager'
            WHEN 3 THEN 'Piéton'
            WHEN 4 THEN 'Piéton mobilité douce'
            ELSE 'Non renseigné'
        END AS libelle_categorie_usager,
        SUM(u.nb_personnes) AS nb_personnes_total,
        SUM(u.nb_tues) AS nb_tues,
        SUM(CASE WHEN u.nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM usagers u
    GROUP BY u.catu
)
SELECT
    code_categorie_usager,
    libelle_categorie_usager,
    nb_tues,
    nb_personnes_total,
    nb_accidents_mortels,
    ROUND(100.0 * nb_tues / NULLIF(SUM(nb_tues) OVER (), 0), 2) AS pct_tues,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_total, 0), 2) AS taux_mortalite_pct
FROM stats
ORDER BY nb_tues DESC;

-- ============================================================================
