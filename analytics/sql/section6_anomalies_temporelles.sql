-- SECTION 6 : DÉTECTION D'ANOMALIES TEMPORELLES (VERSION AGRÉGÉE)
-- =========================================================================
-- Utilise `analytics.accident_usagers_aggr` pour analyser les comportements
-- hebdomadaires et saisonniers sans recalculer les jointures. Les requêtes
-- brutes restent disponibles dans `etl/sql/legacy_section6_anomalies_temporelles.sql`.
-- =========================================================================

-- ----------------------------------------------------------------------------
-- 6.1 Analyse hebdomadaire avec z-score
-- ----------------------------------------------------------------------------
WITH stats_hebdomadaires AS (
    SELECT
        an AS annee,
        EXTRACT(WEEK FROM make_date(an::int, mois::int, jour::int))::INT AS semaine,
        DATE_TRUNC('week', make_date(an::int, mois::int, jour::int))::DATE AS date_debut_semaine,
        COUNT(*) AS nb_accidents,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(100 * nb_tues + 7 * nb_blesses)::NUMERIC AS somme_scores
    FROM analytics.accident_usagers_aggr
    WHERE an IS NOT NULL AND mois IS NOT NULL AND jour IS NOT NULL
    GROUP BY an, EXTRACT(WEEK FROM make_date(an::int, mois::int, jour::int)), DATE_TRUNC('week', make_date(an::int, mois::int, jour::int))
),
hebdo_calc AS (
    SELECT
        annee,
        semaine,
        date_debut_semaine,
        nb_accidents,
        nb_tues,
        CASE WHEN nb_personnes_impliquees = 0 THEN NULL
             ELSE somme_scores / nb_personnes_impliquees END AS gravite_moyenne
    FROM stats_hebdomadaires
),
stats_globales AS (
    SELECT
        AVG(nb_accidents) AS moyenne_accidents,
        STDDEV(nb_accidents) AS ecart_type_accidents,
        AVG(gravite_moyenne) AS moyenne_gravite,
        STDDEV(gravite_moyenne) AS ecart_type_gravite
    FROM hebdo_calc
)
SELECT
    h.annee,
    h.semaine,
    h.date_debut_semaine,
    h.nb_accidents,
    ROUND(sg.moyenne_accidents, 2) AS moyenne_nationale,
    h.nb_accidents - ROUND(sg.moyenne_accidents, 2) AS ecart_absolu,
    ROUND((h.nb_accidents - sg.moyenne_accidents) / NULLIF(sg.ecart_type_accidents, 0), 2) AS z_score_volume,
    ROUND((h.gravite_moyenne - sg.moyenne_gravite) / NULLIF(sg.ecart_type_gravite, 0), 2) AS z_score_gravite,
    h.nb_tues,
    ROUND(h.gravite_moyenne, 2) AS gravite_moyenne,
    CASE
        WHEN ABS((h.nb_accidents - sg.moyenne_accidents) / NULLIF(sg.ecart_type_accidents, 0)) > 3 THEN 'ANOMALIE EXTRÊME (>3σ)'
        WHEN ABS((h.nb_accidents - sg.moyenne_accidents) / NULLIF(sg.ecart_type_accidents, 0)) > 2 THEN 'ANOMALIE FORTE (>2σ)'
        WHEN ABS((h.nb_accidents - sg.moyenne_accidents) / NULLIF(sg.ecart_type_accidents, 0)) > 1.5 THEN 'ANOMALIE MODÉRÉE (>1.5σ)'
        ELSE 'NORMAL'
    END AS type_anomalie,
    CASE
        WHEN (h.nb_accidents - sg.moyenne_accidents) / NULLIF(sg.ecart_type_accidents, 0) > 2 THEN 'PIC d''accidents'
        WHEN (h.nb_accidents - sg.moyenne_accidents) / NULLIF(sg.ecart_type_accidents, 0) < -2 THEN 'CREUX anormal'
        ELSE 'Normal'
    END AS tendance
FROM hebdo_calc h
CROSS JOIN stats_globales sg
WHERE ABS((h.nb_accidents - sg.moyenne_accidents) / NULLIF(sg.ecart_type_accidents, 0)) > 2
ORDER BY ABS((h.nb_accidents - sg.moyenne_accidents) / NULLIF(sg.ecart_type_accidents, 0)) DESC
LIMIT 50;

-- ----------------------------------------------------------------------------
-- 6.2 Analyse des pics d'accidents par période de l'année
-- ----------------------------------------------------------------------------
WITH stats AS (
    SELECT
        mois,
        CASE WHEN EXTRACT(ISODOW FROM make_date(an::int, mois::int, jour::int)) IN (6, 7) THEN TRUE ELSE FALSE END AS est_weekend,
        COUNT(*) AS nb_accidents,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_usagers_total) AS nb_personnes_impliquees,
        SUM(100 * nb_tues + 10 * nb_blesses)::NUMERIC AS somme_scores
    FROM analytics.accident_usagers_aggr
    WHERE an IS NOT NULL AND mois IS NOT NULL AND jour IS NOT NULL
    GROUP BY mois, CASE WHEN EXTRACT(ISODOW FROM make_date(an::int, mois::int, jour::int)) IN (6, 7) THEN TRUE ELSE FALSE END
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
    est_weekend,
    nb_accidents,
    CASE WHEN nb_personnes_impliquees = 0 THEN NULL
         ELSE ROUND(somme_scores / nb_personnes_impliquees, 2) END AS gravite_moyenne,
    nb_tues
FROM stats
ORDER BY mois, est_weekend;

-- =========================================================================
