-- SECTION 3 : IDENTIFIER DES TENDANCES TEMPORELLES
-- ============================================================================

-- ----------------------------------------------------------------------------

-- 3.1 KPI PRIORITAIRE : Nombre d'accidents par années
-- ----------------------------------------------------------------------------


SELECT
    d.an as annee,
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as nb_blesses_hospitalises,
    SUM(CASE WHEN u.grav = 4 THEN 1 ELSE 0 END) as nb_blesses_legers,

    -- Taux
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct,

    -- Évolution année par année
    LAG(COUNT(DISTINCT a.num_acc)) OVER (ORDER BY d.an) as nb_accidents_annee_prec,
    COUNT(DISTINCT a.num_acc) - LAG(COUNT(DISTINCT a.num_acc)) OVER (ORDER BY d.an) as evolution_accidents,
    ROUND(100.0 * (COUNT(DISTINCT a.num_acc) - LAG(COUNT(DISTINCT a.num_acc)) OVER (ORDER BY d.an)) /
          NULLIF(LAG(COUNT(DISTINCT a.num_acc)) OVER (ORDER BY d.an), 0), 2) as pct_evolution

FROM ACCIDENT a
INNER JOIN DATE_ACCIDENT d USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE d.an IS NOT NULL
GROUP BY d.an
ORDER BY d.an;

-- ----------------------------------------------------------------------------

-- 3.2 KPI PRIORITAIRE : Nombre d'accidents par mois (toutes années confondues)
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

    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,

    -- Moyenne par année
    ROUND(COUNT(DISTINCT a.num_acc)::numeric / NULLIF(COUNT(DISTINCT d.an), 0), 2) as moyenne_accidents_par_an,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
          SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct

FROM ACCIDENT a
INNER JOIN DATE_ACCIDENT d USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE d.mois IS NOT NULL
GROUP BY d.mois
ORDER BY d.mois;

-- ----------------------------------------------------------------------------

-- 3.3 KPI PRIORITAIRE : Répartition par heure de la journée (toutes années)
-- ----------------------------------------------------------------------------
-- 🚨 peut être revoir l'utilisation de la table/données temps
SELECT
    LPAD((d.hrmn / 100)::TEXT, 2, '0') as heure,
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
          SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct,

    -- Classification par tranche horaire
    CASE
        WHEN d.hrmn BETWEEN 0 AND 559 THEN 'Nuit (00h-06h)'
        WHEN d.hrmn BETWEEN 600 AND 859 THEN 'Matin (06h-09h)'
        WHEN d.hrmn BETWEEN 900 AND 1159 THEN 'Matinée (09h-12h)'
        WHEN d.hrmn BETWEEN 1200 AND 1359 THEN 'Midi (12h-14h)'
        WHEN d.hrmn BETWEEN 1400 AND 1759 THEN 'Après-midi (14h-18h)'
        WHEN d.hrmn BETWEEN 1800 AND 2159 THEN 'Soirée (18h-22h)'
        WHEN d.hrmn BETWEEN 2200 AND 2359 THEN 'Nuit (22h-00h)'
        ELSE 'Non renseigné'
    END as tranche_horaire

FROM ACCIDENT a
INNER JOIN DATE_ACCIDENT d USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE d.hrmn IS NOT NULL
GROUP BY d.hrmn / 100
ORDER BY d.hrmn / 100;


-- ----------------------------------------------------------------------------

-- 3.4 KPI PRIORITAIRE : Nombre d'accidents par jour de la semaine
-- ----------------------------------------------------------------------------

SELECT
    EXTRACT(ISODOW FROM make_date(d.an, d.mois, d.jour))::INTEGER as numero_jour,
    
    CASE EXTRACT(ISODOW FROM make_date(d.an, d.mois, d.jour))
        WHEN 1 THEN 'Lundi'
        WHEN 2 THEN 'Mardi'
        WHEN 3 THEN 'Mercredi'
        WHEN 4 THEN 'Jeudi'
        WHEN 5 THEN 'Vendredi'
        WHEN 6 THEN 'Samedi'
        WHEN 7 THEN 'Dimanche'
        ELSE 'Non renseigné'
    END as nom_jour,

    CASE
        WHEN EXTRACT(ISODOW FROM make_date(d.an, d.mois, d.jour)) IN (6, 7) THEN 'Weekend'
        ELSE 'Semaine'
    END as type_jour,

    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,

    -- Moyenne par jour
    ROUND(COUNT(DISTINCT a.num_acc)::numeric /
          NULLIF(COUNT(DISTINCT d.datetime::DATE), 0), 2) as moyenne_accidents_par_occurrence,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
          SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct

FROM ACCIDENT a
INNER JOIN DATE_ACCIDENT d USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE d.jour IS NOT NULL
GROUP BY EXTRACT(ISODOW FROM make_date(d.an, d.mois, d.jour))
ORDER BY numero_jour;


-- ----------------------------------------------------------------------------

-- 3.5 KPI SECONDAIRE : Nombre d'accidents mortels par années
-- ----------------------------------------------------------------------------

SELECT
    d.an as annee,
    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as pct_accidents_mortels,

    -- Évolution
    LAG(SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END)) OVER (ORDER BY d.an) as nb_tues_annee_prec,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) -
        LAG(SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END)) OVER (ORDER BY d.an) as evolution_tues,
    ROUND(100.0 * (SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) -
          LAG(SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END)) OVER (ORDER BY d.an)) /
          NULLIF(LAG(SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END)) OVER (ORDER BY d.an), 0), 2) as pct_evolution_tues
    
FROM ACCIDENT a
INNER JOIN DATE_ACCIDENT d USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE d.an IS NOT NULL
GROUP BY d.an
ORDER BY d.an;


-- ----------------------------------------------------------------------------

-- 3.6 KPI SECONDAIRE : Nombre d'accidents mortels par mois (toutes années)
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

    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          SUM(SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END)) OVER (), 2) as pct_tues

FROM ACCIDENT a
INNER JOIN DATE_ACCIDENT d USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE d.mois IS NOT NULL
GROUP BY d.mois
ORDER BY d.mois;


-- ----------------------------------------------------------------------------

-- 3.7 KPI SECONDAIRE : Répartition accidents mortels par heure (toutes années)
-- ----------------------------------------------------------------------------

SELECT
    LPAD((d.hrmn / 100)::TEXT, 2, '0') as heure,
    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels,

    -- Classification par tranche horaire
    CASE
        WHEN d.hrmn BETWEEN 0 AND 559 THEN 'Nuit (00h-06h)'
        WHEN d.hrmn BETWEEN 600 AND 859 THEN 'Matin (06h-09h)'
        WHEN d.hrmn BETWEEN 900 AND 1159 THEN 'Matinée (09h-12h)'
        WHEN d.hrmn BETWEEN 1200 AND 1359 THEN 'Midi (12h-14h)'
        WHEN d.hrmn BETWEEN 1400 AND 1759 THEN 'Après-midi (14h-18h)'
        WHEN d.hrmn BETWEEN 1800 AND 2159 THEN 'Soirée (18h-22h)'
        WHEN d.hrmn BETWEEN 2200 AND 2359 THEN 'Nuit (22h-00h)'
        ELSE 'Non renseigné'
    END as tranche_horaire

FROM ACCIDENT a
INNER JOIN DATE_ACCIDENT d USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE d.hrmn IS NOT NULL
GROUP BY d.hrmn / 100
ORDER BY d.hrmn / 100;


-- ----------------------------------------------------------------------------

-- 3.8 KPI SECONDAIRE : Nombre d'accidents mortels par jour de la semaine
-- ----------------------------------------------------------------------------

SELECT
    EXTRACT(ISODOW FROM make_date(d.an, d.mois, d.jour))::INTEGER as numero_jour,
    
    CASE EXTRACT(ISODOW FROM make_date(d.an, d.mois, d.jour))
        WHEN 1 THEN 'Lundi'
        WHEN 2 THEN 'Mardi'
        WHEN 3 THEN 'Mercredi'
        WHEN 4 THEN 'Jeudi'
        WHEN 5 THEN 'Vendredi'
        WHEN 6 THEN 'Samedi'
        WHEN 7 THEN 'Dimanche'
        ELSE 'Non renseigné'
    END as nom_jour,

    CASE
        WHEN EXTRACT(ISODOW FROM make_date(d.an, d.mois, d.jour)) IN (6, 7) THEN 'Weekend'
        ELSE 'Semaine'
    END as type_jour,

    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as taux_accidents_mortels_pct

FROM ACCIDENT a
INNER JOIN DATE_ACCIDENT d USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE d.an IS NOT NULL AND d.mois IS NOT NULL AND d.jour IS NOT NULL
GROUP BY EXTRACT(ISODOW FROM make_date(d.an, d.mois, d.jour))
ORDER BY numero_jour;


-- ============================================================================
-- PARTIE 2 : ANALYSES AVANCÉES 
-- ============================================================================

-- ============================================================================
