-- SECTION 3 : IDENTIFIER DES TENDANCES TEMPORELLES (VERSION AGRÉGÉE)
-- =========================================================================
-- Toutes les requêtes s'appuient sur la vue `analytics.accident_usagers_aggr`
-- produite dans `setup_dimensions.sql`. Les versions historiques sont
-- conservées dans `etl/sql/legacy_section3_kpi_tendances.sql`.
-- =========================================================================

-- ----------------------------------------------------------------------------
-- 3.1 KPI PRIORITAIRE : Nombre d'accidents par année
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        an AS annee,
        COUNT(*) AS nb_accidents,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(nb_indemnes) AS nb_indemnes,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_blesses_hosp) AS nb_blesses_hospitalises,
        SUM(nb_blesses_legers) AS nb_blesses_legers,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr
    WHERE an IS NOT NULL
    GROUP BY an
)
SELECT
    annee,
    nb_accidents,
    nb_personnes_impliquees,
    nb_indemnes,
    nb_tues,
    nb_blesses_hospitalises,
    nb_blesses_legers,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents, 0), 2) AS pct_accidents_mortels,
    LAG(nb_accidents) OVER (ORDER BY annee) AS nb_accidents_annee_prec,
    nb_accidents - LAG(nb_accidents) OVER (ORDER BY annee) AS evolution_accidents,
    ROUND(100.0 * (nb_accidents - LAG(nb_accidents) OVER (ORDER BY annee)) /
          NULLIF(LAG(nb_accidents) OVER (ORDER BY annee), 0), 2) AS pct_evolution
FROM stats
ORDER BY annee;

-- ----------------------------------------------------------------------------
-- 3.2 KPI PRIORITAIRE : Nombre d'accidents par mois (toutes années)
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        mois,
        COUNT(*) AS nb_accidents,
        COUNT(DISTINCT an) AS nb_annees_observees,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(nb_tues) AS nb_tues
    FROM analytics.accident_usagers_aggr
    WHERE mois IS NOT NULL
    GROUP BY mois
)
SELECT
    mois,
    CASE mois
        WHEN 1 THEN 'Janvier'
        WHEN 2 THEN 'Février'
        WHEN 3 THEN 'Mars'
        WHEN 4 THEN 'Avril'
        WHEN 5 THEN 'Mai'
        WHEN 6 THEN 'Juin'
        WHEN 7 THEN 'Juillet'
        WHEN 8 THEN 'Août'
        WHEN 9 THEN 'Septembre'
        WHEN 10 THEN 'Octobre'
        WHEN 11 THEN 'Novembre'
        WHEN 12 THEN 'Décembre'
    END AS nom_mois,
    nb_accidents,
    nb_personnes_impliquees,
    nb_tues,
    ROUND(nb_accidents::NUMERIC / NULLIF(nb_annees_observees, 0), 2) AS moyenne_accidents_par_an,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct
FROM stats
ORDER BY mois;

-- ----------------------------------------------------------------------------
-- 3.3 KPI PRIORITAIRE : Répartition par heure de la journée
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        CASE WHEN hrmn BETWEEN 0 AND 2359 THEN hrmn / 100 ELSE NULL END AS heure_num,
        COUNT(*) AS nb_accidents,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(nb_tues) AS nb_tues
    FROM analytics.accident_usagers_aggr
    WHERE hrmn IS NOT NULL
    GROUP BY 1
)
SELECT
    CASE
        WHEN heure_num IS NULL THEN 'NR'
        ELSE LPAD(heure_num::TEXT, 2, '0')
    END AS heure,
    nb_accidents,
    nb_personnes_impliquees,
    nb_tues,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    CASE
        WHEN heure_num IS NULL THEN 'Non renseigné'
        WHEN heure_num BETWEEN 0 AND 5 THEN 'Nuit (00h-06h)'
        WHEN heure_num BETWEEN 6 AND 8 THEN 'Matin (06h-09h)'
        WHEN heure_num BETWEEN 9 AND 11 THEN 'Matinée (09h-12h)'
        WHEN heure_num BETWEEN 12 AND 13 THEN 'Midi (12h-14h)'
        WHEN heure_num BETWEEN 14 AND 17 THEN 'Après-midi (14h-18h)'
        WHEN heure_num BETWEEN 18 AND 21 THEN 'Soirée (18h-22h)'
        WHEN heure_num BETWEEN 22 AND 23 THEN 'Nuit (22h-00h)'
        ELSE 'Non renseigné'
    END AS tranche_horaire
FROM stats
ORDER BY heure_num NULLS LAST;

-- ----------------------------------------------------------------------------
-- 3.4 KPI PRIORITAIRE : Nombre d'accidents par jour de la semaine
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        EXTRACT(ISODOW FROM make_date(an, mois, jour))::INT AS numero_jour,
        COUNT(*) AS nb_accidents,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(nb_tues) AS nb_tues,
        COUNT(DISTINCT make_date(an, mois, jour)) AS nb_jours_observes
    FROM analytics.accident_usagers_aggr
    WHERE an IS NOT NULL AND mois IS NOT NULL AND jour IS NOT NULL
    GROUP BY 1
)
SELECT
    numero_jour,
    CASE numero_jour
        WHEN 1 THEN 'Lundi'
        WHEN 2 THEN 'Mardi'
        WHEN 3 THEN 'Mercredi'
        WHEN 4 THEN 'Jeudi'
        WHEN 5 THEN 'Vendredi'
        WHEN 6 THEN 'Samedi'
        WHEN 7 THEN 'Dimanche'
        ELSE 'Non renseigné'
    END AS nom_jour,
    CASE
        WHEN numero_jour IN (6, 7) THEN 'Weekend'
        WHEN numero_jour BETWEEN 1 AND 5 THEN 'Semaine'
        ELSE 'Indéterminé'
    END AS type_jour,
    nb_accidents,
    nb_personnes_impliquees,
    nb_tues,
    ROUND(nb_accidents::NUMERIC / NULLIF(nb_jours_observes, 0), 2) AS moyenne_accidents_par_occurrence,
    ROUND(100.0 * nb_accidents / NULLIF(SUM(nb_accidents) OVER (), 0), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct
FROM stats
ORDER BY numero_jour;

-- ----------------------------------------------------------------------------
-- 3.5 KPI SECONDAIRE : Nombre d'accidents mortels par année
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        an AS annee,
        COUNT(*) AS nb_accidents_total,
        SUM(nb_tues) AS nb_tues,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr
    WHERE an IS NOT NULL
    GROUP BY an
)
SELECT
    annee,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents_total,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents_total, 0), 2) AS pct_accidents_mortels,
    LAG(nb_tues) OVER (ORDER BY annee) AS nb_tues_annee_prec,
    nb_tues - LAG(nb_tues) OVER (ORDER BY annee) AS evolution_tues,
    ROUND(100.0 * (nb_tues - LAG(nb_tues) OVER (ORDER BY annee)) /
          NULLIF(LAG(nb_tues) OVER (ORDER BY annee), 0), 2) AS pct_evolution_tues
FROM stats
ORDER BY annee;

-- ----------------------------------------------------------------------------
-- 3.6 KPI SECONDAIRE : Nombre d'accidents mortels par mois (toutes années)
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        mois,
        COUNT(*) AS nb_accidents_total,
        SUM(nb_tues) AS nb_tues,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr
    WHERE mois IS NOT NULL
    GROUP BY mois
)
SELECT
    mois,
    CASE mois
        WHEN 1 THEN 'Janvier'
        WHEN 2 THEN 'Février'
        WHEN 3 THEN 'Mars'
        WHEN 4 THEN 'Avril'
        WHEN 5 THEN 'Mai'
        WHEN 6 THEN 'Juin'
        WHEN 7 THEN 'Juillet'
        WHEN 8 THEN 'Août'
        WHEN 9 THEN 'Septembre'
        WHEN 10 THEN 'Octobre'
        WHEN 11 THEN 'Novembre'
        WHEN 12 THEN 'Décembre'
    END AS nom_mois,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents_total,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(SUM(nb_accidents_mortels) OVER (), 0), 2) AS pct_accidents_mortels,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents_total, 0), 2) AS taux_accidents_mortels_pct
FROM stats
ORDER BY mois;

-- ----------------------------------------------------------------------------
-- 3.7 KPI SECONDAIRE : Répartition des accidents mortels par heure
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        CASE WHEN hrmn BETWEEN 0 AND 2359 THEN hrmn / 100 ELSE NULL END AS heure_num,
        COUNT(*) AS nb_accidents_total,
        SUM(nb_tues) AS nb_tues,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr
    WHERE hrmn IS NOT NULL
    GROUP BY 1
)
SELECT
    CASE
        WHEN heure_num IS NULL THEN 'NR'
        ELSE LPAD(heure_num::TEXT, 2, '0')
    END AS heure,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents_total,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(SUM(nb_accidents_mortels) OVER (), 0), 2) AS pct_accidents_mortels,
    CASE
        WHEN heure_num IS NULL THEN 'Non renseigné'
        WHEN heure_num BETWEEN 0 AND 5 THEN 'Nuit (00h-06h)'
        WHEN heure_num BETWEEN 6 AND 8 THEN 'Matin (06h-09h)'
        WHEN heure_num BETWEEN 9 AND 11 THEN 'Matinée (09h-12h)'
        WHEN heure_num BETWEEN 12 AND 13 THEN 'Midi (12h-14h)'
        WHEN heure_num BETWEEN 14 AND 17 THEN 'Après-midi (14h-18h)'
        WHEN heure_num BETWEEN 18 AND 21 THEN 'Soirée (18h-22h)'
        WHEN heure_num BETWEEN 22 AND 23 THEN 'Nuit (22h-00h)'
        ELSE 'Non renseigné'
    END AS tranche_horaire
FROM stats
ORDER BY heure_num NULLS LAST;

-- ----------------------------------------------------------------------------
-- 3.8 KPI SECONDAIRE : Nombre d'accidents mortels par jour de la semaine
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        EXTRACT(ISODOW FROM make_date(an, mois, jour))::INT AS numero_jour,
        COUNT(*) AS nb_accidents_total,
        SUM(nb_tues) AS nb_tues,
        SUM(CASE WHEN nb_tues > 0 THEN 1 ELSE 0 END) AS nb_accidents_mortels
    FROM analytics.accident_usagers_aggr
    WHERE an IS NOT NULL AND mois IS NOT NULL AND jour IS NOT NULL
    GROUP BY 1
)
SELECT
    numero_jour,
    CASE numero_jour
        WHEN 1 THEN 'Lundi'
        WHEN 2 THEN 'Mardi'
        WHEN 3 THEN 'Mercredi'
        WHEN 4 THEN 'Jeudi'
        WHEN 5 THEN 'Vendredi'
        WHEN 6 THEN 'Samedi'
        WHEN 7 THEN 'Dimanche'
        ELSE 'Non renseigné'
    END AS nom_jour,
    CASE
        WHEN numero_jour IN (6, 7) THEN 'Weekend'
        WHEN numero_jour BETWEEN 1 AND 5 THEN 'Semaine'
        ELSE 'Indéterminé'
    END AS type_jour,
    nb_accidents_mortels,
    nb_tues,
    nb_accidents_total,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(SUM(nb_accidents_mortels) OVER (), 0), 2) AS pct_accidents_mortels,
    ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents_total, 0), 2) AS taux_accidents_mortels_pct
FROM stats
ORDER BY numero_jour;

-- =========================================================================
