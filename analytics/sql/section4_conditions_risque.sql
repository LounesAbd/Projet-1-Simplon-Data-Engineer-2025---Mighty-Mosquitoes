-- SECTION 4 : CONDITIONS À RISQUE (ANALYSE AVANCÉE - VERSION AGRÉGÉE)
-- =========================================================================
-- Exploite la vue `analytics.accident_usagers_aggr` et les dimensions métiers
-- pour identifier les combinaisons météo / luminosité / type de route à fort
-- risque. Les requêtes historiques sont préservées dans
-- `etl/sql/legacy_section4_conditions_risque.sql`.
-- =========================================================================

-- ----------------------------------------------------------------------------
-- 4.1 Combinaisons de conditions les plus dangereuses (z-score)
-- ----------------------------------------------------------------------------
WITH statistiques_nationales AS (
    SELECT
        COUNT(*) AS nb_accidents_total,
        SUM(nb_usagers_total) AS nb_victimes_total,
        SUM(nb_tues) AS total_tues,
        SUM(nb_blesses_hosp) AS total_blesses_hospitalises,
        SUM(nb_blesses_legers) AS total_blesses_legers,
        SUM(100 * nb_tues + 10 * nb_blesses_hosp + nb_blesses_legers) AS somme_scores,
        SUM(10000 * nb_tues + 100 * nb_blesses_hosp + nb_blesses_legers) AS somme_scores_carres
    FROM analytics.accident_usagers_aggr
),
analyse_conditions AS (
    SELECT
        aua.atm,
        COALESCE(da.libelle, 'Non renseigné') AS libelle_meteo,
        aua.lum,
        COALESCE(dl.libelle, 'Non renseigné') AS libelle_lumiere,
        aua.catr,
        COALESCE(dc.libelle, 'Non renseigné') AS libelle_categorie_route,
        COUNT(*) AS nb_accidents,
        SUM(nb_usagers_total) AS nb_impliques,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_blesses_hosp) AS nb_blesses_hospitalises,
        SUM(nb_blesses_legers) AS nb_blesses_legers,
        SUM(100 * nb_tues + 10 * nb_blesses_hosp + nb_blesses_legers) AS somme_scores,
        SUM(10000 * nb_tues + 100 * nb_blesses_hosp + nb_blesses_legers) AS somme_scores_carres,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels,
        SUM(CASE WHEN nb_tues > 0 OR nb_blesses_hosp > 0 THEN 1 ELSE 0 END) AS nb_accidents_graves
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_atm da ON da.atm = aua.atm
    LEFT JOIN analytics.dim_lum dl ON dl.lum = aua.lum
    LEFT JOIN analytics.dim_catr dc ON dc.catr = aua.catr
    GROUP BY aua.atm, da.libelle, aua.lum, dl.libelle, aua.catr, dc.libelle
    HAVING COUNT(*) >= 100
)
SELECT
    ac.libelle_meteo,
    ac.libelle_lumiere,
    ac.libelle_categorie_route,
    ac.nb_accidents,
    ac.nb_tues,
    ac.nb_blesses_hospitalises,
    ROUND(ac.somme_scores::NUMERIC / NULLIF(ac.nb_impliques, 0), 2) AS gravite_moyenne,
    ROUND(CASE
        WHEN ac.nb_tues > 0 THEN 100
        WHEN ac.nb_blesses_hospitalises > 0 THEN 10
        WHEN ac.nb_blesses_legers > 0 THEN 1
        ELSE 0
    END, 2) AS gravite_max,
    sn.gravite_moyenne_nationale,
    ROUND((ac.somme_scores::NUMERIC / NULLIF(ac.nb_impliques, 0)) - sn.gravite_moyenne_nationale, 2) AS ecart_gravite,
    ROUND(((ac.somme_scores::NUMERIC / NULLIF(ac.nb_impliques, 0)) - sn.gravite_moyenne_nationale) /
          NULLIF(sn.ecart_type_gravite, 0), 2) AS z_score,
    ROUND(100.0 * ac.nb_tues / NULLIF(ac.nb_impliques, 0), 2) AS taux_mortalite,
    ROUND(100.0 * ac.nb_accidents_mortels / NULLIF(ac.nb_accidents, 0), 2) AS pct_accidents_mortels,
    ROUND(100.0 * ac.nb_accidents_graves / NULLIF(ac.nb_accidents, 0), 2) AS pct_accidents_graves,
    CASE
        WHEN ((ac.somme_scores::NUMERIC / NULLIF(ac.nb_impliques, 0)) - sn.gravite_moyenne_nationale) /
             NULLIF(sn.ecart_type_gravite, 0) > 2 THEN 'RISQUE TRÈS ÉLEVÉ'
        WHEN ((ac.somme_scores::NUMERIC / NULLIF(ac.nb_impliques, 0)) - sn.gravite_moyenne_nationale) /
             NULLIF(sn.ecart_type_gravite, 0) > 1 THEN 'RISQUE ÉLEVÉ'
        WHEN ((ac.somme_scores::NUMERIC / NULLIF(ac.nb_impliques, 0)) - sn.gravite_moyenne_nationale) /
             NULLIF(sn.ecart_type_gravite, 0) > 0 THEN 'RISQUE MODÉRÉ'
        ELSE 'RISQUE FAIBLE'
    END AS niveau_risque
FROM analyse_conditions ac
CROSS JOIN (
    SELECT
        somme_scores::NUMERIC / NULLIF(nb_victimes_total, 0) AS gravite_moyenne_nationale,
        SQRT(GREATEST(somme_scores_carres::NUMERIC / NULLIF(nb_victimes_total, 0) -
             POWER(somme_scores::NUMERIC / NULLIF(nb_victimes_total, 0), 2), 0)) AS ecart_type_gravite
    FROM statistiques_nationales
) AS sn
ORDER BY gravite_moyenne DESC, nb_accidents DESC
LIMIT 30;

-- ----------------------------------------------------------------------------
-- 4.2 Focus sur les conditions météo défavorables
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.atm AS code_meteo,
        COALESCE(da.libelle, 'Non renseigné') AS libelle_meteo,
        COUNT(*) AS nb_accidents,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_blesses_hosp) AS nb_blesses_hospitalises,
        SUM(100 * nb_tues + 10 * nb_blesses_hosp + nb_blesses_legers) AS somme_scores
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_atm da ON da.atm = aua.atm
    GROUP BY aua.atm, da.libelle
)
SELECT
    code_meteo,
    libelle_meteo,
    nb_accidents,
    nb_tues,
    nb_blesses_hospitalises,
    ROUND(somme_scores::NUMERIC / NULLIF(nb_personnes_impliquees, 0), 2) AS gravite_moyenne,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite
FROM stats
ORDER BY gravite_moyenne DESC;

-- ----------------------------------------------------------------------------
-- 4.3 Impact de la luminosité
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        aua.lum AS code_lumiere,
        COALESCE(dl.libelle, 'Non renseigné') AS libelle_lumiere,
        COUNT(*) AS nb_accidents,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_blesses_hosp) AS nb_blesses_hospitalises,
        SUM(100 * nb_tues + 10 * nb_blesses_hosp + nb_blesses_legers) AS somme_scores,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_lum dl ON dl.lum = aua.lum
    GROUP BY aua.lum, dl.libelle
)
SELECT
    code_lumiere,
    libelle_lumiere,
    nb_accidents,
    nb_tues,
    nb_blesses_hospitalises,
    ROUND(somme_scores::NUMERIC / NULLIF(nb_personnes_impliquees, 0), 2) AS gravite_moyenne,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents, 0), 2) AS pct_accidents_mortels
FROM stats
ORDER BY gravite_moyenne DESC;

-- =========================================================================
