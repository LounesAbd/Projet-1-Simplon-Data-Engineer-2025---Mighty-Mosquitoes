-- SECTION 6 : DÉTECTION D'ANOMALIES TEMPORELLES
-- ============================================================================
-- Objectif : Identifier les semaines où le nombre d'accidents s'écarte fortement
--            de la moyenne (détection d'anomalies temporelles)
-- ============================================================================

-- ----------------------------------------------------------------------------

-- 6.1 Analyse des semaines avec z-score (écart normalisé)
-- ----------------------------------------------------------------------------

WITH stats_hebdomadaires AS (
    -- Comptage des accidents par semaine
    SELECT
        d.an as annee,
        EXTRACT(WEEK FROM make_date(d.an, d.mois, d.jour)) as semaine,
        DATE_TRUNC('week', make_date(d.an, d.mois, d.jour))::DATE as date_debut_semaine,
        COUNT(DISTINCT a.num_acc) as nb_accidents,
        SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
        AVG(CASE
            WHEN u.grav = 2 THEN 100
            WHEN u.grav = 3 THEN 10
            WHEN u.grav = 4 THEN 1
            ELSE 0
        END) as gravite_moyenne
    FROM ACCIDENT a
    INNER JOIN DATE_ACCIDENT d USING (num_acc)
    INNER JOIN USAGER u USING (num_acc)
    WHERE d.an IS NOT NULL AND d.mois IS NOT NULL AND d.jour IS NOT NULL
    GROUP BY d.an, EXTRACT(WEEK FROM make_date(d.an, d.mois, d.jour)), DATE_TRUNC('week', make_date(d.an, d.mois, d.jour))
    ORDER BY d.an, semaine
),
stats_globales AS (
    -- Moyenne et écart-type sur toutes les semaines
    SELECT
        AVG(nb_accidents) as moyenne_accidents,
        STDDEV(nb_accidents) as ecart_type_accidents,
        AVG(gravite_moyenne) as moyenne_gravite,
        STDDEV(gravite_moyenne) as ecart_type_gravite
    FROM stats_hebdomadaires
)
SELECT
    sh.annee,
    sh.semaine,
    sh.date_debut_semaine,
    sh.nb_accidents,
    ROUND(sg.moyenne_accidents, 2) as moyenne_nationale,
    sh.nb_accidents - ROUND(sg.moyenne_accidents, 2) as ecart_absolu,

    -- Z-score (écart normalisé)
    ROUND((sh.nb_accidents - sg.moyenne_accidents) /
          NULLIF(sg.ecart_type_accidents, 0), 2) as z_score_volume,
    ROUND((sh.gravite_moyenne - sg.moyenne_gravite) /
          NULLIF(sg.ecart_type_gravite, 0), 2) as z_score_gravite,

    sh.nb_tues,
    ROUND(sh.gravite_moyenne, 2) as gravite_moyenne,

    -- Classification de l'anomalie
    CASE
        WHEN ABS((sh.nb_accidents - sg.moyenne_accidents) /
             NULLIF(sg.ecart_type_accidents, 0)) > 3 THEN 'ANOMALIE EXTRÊME (>3σ)'
        WHEN ABS((sh.nb_accidents - sg.moyenne_accidents) /
             NULLIF(sg.ecart_type_accidents, 0)) > 2 THEN 'ANOMALIE FORTE (>2σ)'
        WHEN ABS((sh.nb_accidents - sg.moyenne_accidents) /
             NULLIF(sg.ecart_type_accidents, 0)) > 1.5 THEN 'ANOMALIE MODÉRÉE (>1.5σ)'
        ELSE 'NORMAL'
    END as type_anomalie,

    -- Direction de l'anomalie
    CASE
        WHEN (sh.nb_accidents - sg.moyenne_accidents) /
             NULLIF(sg.ecart_type_accidents, 0) > 2 THEN 'PIC d''accidents'
        WHEN (sh.nb_accidents - sg.moyenne_accidents) /
             NULLIF(sg.ecart_type_accidents, 0) < -2 THEN 'CREUX anormal'
        ELSE 'Normal'
    END as tendance

FROM stats_hebdomadaires sh
CROSS JOIN stats_globales sg

-- Filtrer uniquement les semaines anormales (|z-score| > 2)
WHERE ABS((sh.nb_accidents - sg.moyenne_accidents) /
      NULLIF(sg.ecart_type_accidents, 0)) > 2

ORDER BY ABS((sh.nb_accidents - sg.moyenne_accidents) /
         NULLIF(sg.ecart_type_accidents, 0)) DESC
LIMIT 50;



-- ----------------------------------------------------------------------------

-- 6.2 Analyse des pics d'accidents par période de l'année
-- ----------------------------------------------------------------------------

SELECT
    d.mois,
    CASE d.mois
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
    END as nom_mois,
    CASE
        WHEN EXTRACT(ISODOW FROM make_date(d.an, d.mois, d.jour)) IN (6, 7) THEN TRUE
        ELSE FALSE
    END as est_weekend,
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    AVG(CASE
        WHEN u.grav = 2 THEN 100
        WHEN u.grav = 3 THEN 10
        WHEN u.grav = 4 THEN 1
        ELSE 0
    END) as gravite_moyenne,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues
FROM ACCIDENT a
INNER JOIN DATE_ACCIDENT d USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE d.an IS NOT NULL AND d.mois IS NOT NULL AND d.jour IS NOT NULL
GROUP BY d.mois, CASE WHEN EXTRACT(ISODOW FROM make_date(d.an, d.mois, d.jour)) IN (6, 7) THEN TRUE ELSE FALSE END
ORDER BY d.mois, est_weekend;



-- ============================================================================
