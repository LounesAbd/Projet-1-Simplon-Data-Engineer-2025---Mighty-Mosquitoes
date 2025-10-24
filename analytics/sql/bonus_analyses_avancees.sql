-- ============================================================================
-- BONUS : ANALYSES AVANCÉES
-- ============================================================================
-- Deux requêtes innovantes pour une analyse approfondie des accidents
--
-- Requête 1 : "Cocktail mortel" - Combinaisons multi-facteurs à haut risque
-- Requête 2 : "Effet week-end saisonnier" - Pics temporels dangereux
-- ============================================================================

-- ----------------------------------------------------------------------------
-- REQUÊTE 1 : "COCKTAIL MORTEL"
-- Analyse des combinaisons multi-facteurs (atmosphère × luminosité × route × heure × agglo)
-- avec score de létalité pour identifier les situations les plus dangereuses
-- ----------------------------------------------------------------------------

WITH combinaisons AS (
    SELECT
        a.atm AS atmosphere,
        a.lum AS luminosite,
        l.catr AS type_route,
        a.agg AS agglomeration,
        CASE
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 0 AND 5 THEN 'Nuit (00h-06h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 6 AND 8 THEN 'Matin (06h-09h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 9 AND 11 THEN 'Matinée (09h-12h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 12 AND 13 THEN 'Midi (12h-14h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 14 AND 17 THEN 'Après-midi (14h-18h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 18 AND 21 THEN 'Soirée (18h-22h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 22 AND 23 THEN 'Nuit (22h-00h)'
            ELSE 'Non renseigné'
        END AS tranche_horaire,
        COUNT(DISTINCT a.num_acc) AS nb_accidents,
        COUNT(DISTINCT CASE WHEN u.grav = 'Tué' THEN a.num_acc END) AS nb_accidents_mortels,
        SUM(CASE WHEN u.grav = 'Tué' THEN 1 ELSE 0 END) AS nb_tues,
        SUM(CASE WHEN u.grav = 'Blessés' THEN 1 ELSE 0 END) AS nb_blesses,
        COUNT(*) AS nb_personnes_impliquees
    FROM ACCIDENT a
    INNER JOIN LIEUX l ON a.num_acc = l.num_acc
    INNER JOIN DATE_ACCIDENT d ON a.num_acc = d.num_acc
    INNER JOIN USAGER u ON a.num_acc = u.num_acc
    WHERE a.atm IS NOT NULL
        AND a.lum IS NOT NULL
        AND l.catr IS NOT NULL
        AND a.agg IS NOT NULL
        AND d.hrmn IS NOT NULL
    GROUP BY a.atm, a.lum, l.catr, a.agg, tranche_horaire
    HAVING COUNT(DISTINCT a.num_acc) >= 50  -- Filtrer les combinaisons trop rares
),
statistiques AS (
    SELECT
        *,
        -- Score de gravité : 100 points par tué + 10 par blessés + 1 par blessé léger
        (100.0 * nb_tues + 7.0 * nb_blesses) /
            NULLIF(nb_personnes_impliquees, 0) AS score_gravite,
        -- Taux de mortalité
        ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
        -- Taux d'accidents mortels
        ROUND(100.0 * nb_accidents_mortels / NULLIF(nb_accidents, 0), 2) AS pct_accidents_mortels
    FROM combinaisons
),
avec_zscore AS (
    SELECT
        *,
        -- Z-score du score de gravité (écart à la moyenne en nombre d'écarts-types)
        ROUND(
            (score_gravite - AVG(score_gravite) OVER ()) /
            NULLIF(STDDEV(score_gravite) OVER (), 0),
            2
        ) AS z_score_gravite,
        -- Classement par dangerosité
        DENSE_RANK() OVER (ORDER BY score_gravite DESC) AS rang_danger
    FROM statistiques
)
SELECT
    atmosphere,
    luminosite,
    type_route,
    agglomeration,
    tranche_horaire,
    nb_accidents,
    nb_tues,
    nb_blesses,
    nb_personnes_impliquees,
    ROUND(score_gravite, 2) AS score_gravite,
    taux_mortalite_pct,
    pct_accidents_mortels,
    z_score_gravite,
    rang_danger,
    CASE
        WHEN z_score_gravite > 2.5 THEN '🔴 EXTRÊMEMENT DANGEREUX'
        WHEN z_score_gravite > 1.5 THEN '🟠 TRÈS DANGEREUX'
        WHEN z_score_gravite > 0.5 THEN '🟡 DANGEREUX'
        ELSE '🟢 RISQUE MODÉRÉ'
    END AS niveau_risque
FROM avec_zscore
ORDER BY score_gravite DESC, nb_accidents DESC
LIMIT 30;


-- ----------------------------------------------------------------------------
-- REQUÊTE 2 : "EFFET WEEK-END SAISONNIER"
-- Croisement jour de semaine × mois × tranche horaire pour identifier les pics
-- temporels dangereux (ex: vendredis soirs d'été, dimanches soirs de retour de vacances)
-- ----------------------------------------------------------------------------

WITH analyse_temporelle AS (
    SELECT
        -- Jour de la semaine
        CASE EXTRACT(ISODOW FROM make_date(d.an::int, d.mois::int, d.jour::int))
            WHEN 1 THEN 'Lundi'
            WHEN 2 THEN 'Mardi'
            WHEN 3 THEN 'Mercredi'
            WHEN 4 THEN 'Jeudi'
            WHEN 5 THEN 'Vendredi'
            WHEN 6 THEN 'Samedi'
            WHEN 7 THEN 'Dimanche'
        END AS jour_semaine,
        EXTRACT(ISODOW FROM make_date(d.an::int, d.mois::int, d.jour::int))::INT AS numero_jour,
        -- Type de jour
        CASE
            WHEN EXTRACT(ISODOW FROM make_date(d.an::int, d.mois::int, d.jour::int)) IN (6, 7)
            THEN 'Week-end'
            ELSE 'Semaine'
        END AS type_jour,
        -- Mois
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
        END AS mois_nom,
        d.mois AS mois_numero,
        -- Saison
        CASE
            WHEN d.mois IN (12, 1, 2) THEN 'Hiver'
            WHEN d.mois IN (3, 4, 5) THEN 'Printemps'
            WHEN d.mois IN (6, 7, 8) THEN 'Été'
            WHEN d.mois IN (9, 10, 11) THEN 'Automne'
        END AS saison,
        -- Tranche horaire
        CASE
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 0 AND 5 THEN 'Nuit profonde (00h-06h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 6 AND 8 THEN 'Matin rush (06h-09h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 9 AND 11 THEN 'Matinée (09h-12h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 12 AND 13 THEN 'Pause déjeuner (12h-14h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 14 AND 17 THEN 'Après-midi (14h-18h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 18 AND 21 THEN 'Soirée rush (18h-22h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 22 AND 23 THEN 'Nuit (22h-00h)'
            ELSE 'Non renseigné'
        END AS tranche_horaire,
        -- Métriques
        COUNT(DISTINCT a.num_acc) AS nb_accidents,
        SUM(CASE WHEN u.grav = 'Tué' THEN 1 ELSE 0 END) AS nb_tues,
        SUM(CASE WHEN u.grav = 'Blessés' THEN 1 ELSE 0 END) AS nb_blesses,
        COUNT(*) AS nb_personnes_impliquees,
        COUNT(DISTINCT CASE WHEN u.grav = 'Tué' THEN a.num_acc END) AS nb_accidents_mortels
    FROM ACCIDENT a
    INNER JOIN DATE_ACCIDENT d ON a.num_acc = d.num_acc
    INNER JOIN USAGER u ON a.num_acc = u.num_acc
    WHERE d.an IS NOT NULL
        AND d.mois IS NOT NULL
        AND d.jour IS NOT NULL
        AND d.hrmn IS NOT NULL
    GROUP BY
        numero_jour, jour_semaine, type_jour,
        mois_numero, mois_nom, saison,
        tranche_horaire
),
avec_statistiques AS (
    SELECT
        *,
        -- Score de gravité
        ROUND(
            (100.0 * nb_tues + 7.0 * nb_blesses) /
            NULLIF(nb_personnes_impliquees, 0),
            2
        ) AS score_gravite,
        -- Taux de mortalité
        ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
        -- Fréquence relative (par rapport à la moyenne de la même catégorie)
        ROUND(
            100.0 * nb_accidents /
            NULLIF(AVG(nb_accidents) OVER (PARTITION BY type_jour), 0),
            2
        ) AS indice_frequence_relative
    FROM analyse_temporelle
),
classement AS (
    SELECT
        *,
        -- Rang par gravité
        DENSE_RANK() OVER (ORDER BY score_gravite DESC, nb_accidents DESC) AS rang_gravite,
        -- Rang par fréquence
        DENSE_RANK() OVER (ORDER BY nb_accidents DESC) AS rang_frequence,
        -- Score combiné (fréquence × gravité)
        ROUND(nb_accidents * score_gravite, 2) AS score_combine
    FROM avec_statistiques
)
SELECT
    jour_semaine,
    numero_jour,
    type_jour,
    mois_nom,
    saison,
    tranche_horaire,
    nb_accidents,
    nb_tues,
    nb_blesses,
    score_gravite,
    taux_mortalite_pct,
    indice_frequence_relative,
    score_combine,
    rang_gravite,
    rang_frequence,
    CASE
        WHEN score_combine > 5000 THEN '🔴 PÉRIODE CRITIQUE'
        WHEN score_combine > 2000 THEN '🟠 PÉRIODE À RISQUE ÉLEVÉ'
        WHEN score_combine > 1000 THEN '🟡 PÉRIODE À SURVEILLER'
        ELSE '🟢 PÉRIODE NORMALE'
    END AS alerte_periode
FROM classement
WHERE nb_accidents >= 100  -- Filtrer les périodes avec volume significatif
ORDER BY score_combine DESC
LIMIT 50;


-- ----------------------------------------------------------------------------
-- REQUÊTE 3 (BONUS) : VUE D'ENSEMBLE RAPIDE - Pour les KPI de la section 1
-- ----------------------------------------------------------------------------

SELECT
    'Période couverte' AS metrique,
    MIN(make_date(d.an, d.mois, d.jour))::TEXT || ' à ' ||
    MAX(make_date(d.an, d.mois, d.jour))::TEXT AS valeur
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
    'Nombre total de tués',
    SUM(CASE WHEN grav = 'Tué' THEN 1 ELSE 0 END)::TEXT
FROM USAGER
UNION ALL
SELECT
    'Nombre total de blessés hospitalisés',
    SUM(CASE WHEN grav = 'Blessés' THEN 1 ELSE 0 END)::TEXT
FROM USAGER
UNION ALL
SELECT
    'Taux de mortalité global (%)',
    ROUND(100.0 * SUM(CASE WHEN grav = 'Tué' THEN 1 ELSE 0 END) /
          NULLIF(COUNT(*), 0), 2)::TEXT
FROM USAGER
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

-- ============================================================================
-- Fin du fichier bonus_analyses_avancees.sql
-- ============================================================================
