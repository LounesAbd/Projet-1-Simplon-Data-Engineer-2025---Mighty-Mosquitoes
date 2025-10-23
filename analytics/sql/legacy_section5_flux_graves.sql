-- SECTION 5 : ZONES FRÉQUENTÉES vs ACCIDENTS GRAVES
-- ============================================================================
-- Objectif : Déterminer si les zones les plus fréquentées ont plus d'accidents graves
--            ou simplement plus d'accidents au total
-- ============================================================================

-- ----------------------------------------------------------------------------

-- 5.1 Analyse par département (volume vs gravité)
-- ----------------------------------------------------------------------------

WITH stats_departements AS (
    SELECT
        l.dep_code as departement,
        l.dep_name as nom_departement,

        -- Volume d'accidents
        COUNT(DISTINCT a.num_acc) as nb_accidents,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT a.num_acc) DESC) as rang_volume,

        -- Gravité
        SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
        SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as nb_blesses_hospitalises,
        SUM(CASE WHEN u.grav = 4 THEN 1 ELSE 0 END) as nb_blesses_legers,
        AVG(CASE
            WHEN u.grav = 2 THEN 100
            WHEN u.grav = 3 THEN 10
            WHEN u.grav = 4 THEN 1
            ELSE 0
        END) as gravite_moyenne,

        -- Taux de gravité
        ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav IN (2,3) THEN a.num_acc END) /
              NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as taux_accidents_graves,
        ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
              NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite,

        -- Classement par gravité
        DENSE_RANK() OVER (ORDER BY AVG(CASE
            WHEN u.grav = 2 THEN 100
            WHEN u.grav = 3 THEN 10
            WHEN u.grav = 4 THEN 1
            ELSE 0
        END) DESC) as rang_gravite

    FROM ACCIDENT a
    INNER JOIN LIEUX l USING (num_acc)
    INNER JOIN USAGER u USING (num_acc)
    WHERE l.dep_code IS NOT NULL
    GROUP BY l.dep_code, l.dep_name
)
SELECT
    departement,
    nom_departement,
    nb_accidents,
    rang_volume,
    ROUND(gravite_moyenne, 2) as gravite_moyenne,
    rang_gravite,
    taux_accidents_graves,
    taux_mortalite,
    nb_tues,
    nb_blesses_hospitalises,

    -- Analyse : corrélation volume / gravité
    CASE
        WHEN rang_volume <= 10 AND rang_gravite <= 10 THEN 'Zone dense ET dangereuse'
        WHEN rang_volume <= 10 AND rang_gravite > 50 THEN 'Zone dense mais PEU dangereuse'
        WHEN rang_volume > 50 AND rang_gravite <= 10 THEN 'Zone peu dense mais TRÈS dangereuse'
        ELSE 'Zone moyenne'
    END as profil_zone

FROM stats_departements
ORDER BY nb_accidents DESC
LIMIT 50;


-- ----------------------------------------------------------------------------

-- 5.2 Corrélation statistique entre volume et gravité
-- ----------------------------------------------------------------------------
-- Coefficient de corrélation de Pearson voir si il y a correlation entre volume et gravité (scatter plot)
WITH stats_par_dept AS (
    SELECT
        l.dep_code as departement,
        COUNT(DISTINCT a.num_acc) as nb_accidents,
        AVG(CASE
            WHEN u.grav = 2 THEN 100
            WHEN u.grav = 3 THEN 10
            WHEN u.grav = 4 THEN 1
            ELSE 0
        END) as gravite_moyenne
    FROM ACCIDENT a
    INNER JOIN LIEUX l USING (num_acc)
    INNER JOIN USAGER u USING (num_acc)
    WHERE l.dep_code IS NOT NULL
    GROUP BY l.dep_code
)
SELECT
    -- Coefficient de corrélation de Pearson
    ROUND(CORR(nb_accidents, gravite_moyenne)::numeric, 3) as correlation_volume_gravite,

    -- Interprétation
    CASE
        WHEN ABS(CORR(nb_accidents, gravite_moyenne)) < 0.3 THEN 'Corrélation FAIBLE : Le volume d''accidents n''explique PAS la gravité'
        WHEN ABS(CORR(nb_accidents, gravite_moyenne)) < 0.7 THEN 'Corrélation MODÉRÉE'
        ELSE 'Corrélation FORTE : Le volume d''accidents explique la gravité'
    END as interpretation

FROM stats_par_dept;


-- ----------------------------------------------------------------------------

-- 5.3 Top 10 départements les plus fréquentés vs Top 10 les plus dangereux
-- ----------------------------------------------------------------------------

-- Top 10 par volume
(
    SELECT
        'TOP VOLUME' as categorie,
        l.dep_code as departement,
        l.dep_name as nom_departement,
        COUNT(DISTINCT a.num_acc) as nb_accidents,
        AVG(CASE
            WHEN u.grav = 2 THEN 100
            WHEN u.grav = 3 THEN 10
            WHEN u.grav = 4 THEN 1
            ELSE 0
        END) as gravite_moyenne
    FROM ACCIDENT a
    INNER JOIN LIEUX l USING (num_acc)
    INNER JOIN USAGER u USING (num_acc)
    WHERE l.dep_code IS NOT NULL
    GROUP BY l.dep_code, l.dep_name
    ORDER BY nb_accidents DESC
    LIMIT 10
)
UNION ALL
-- Top 10 par gravité
(
    SELECT
        'TOP GRAVITÉ' as categorie,
        l.dep_code as departement,
        l.dep_name as nom_departement,
        COUNT(DISTINCT a.num_acc) as nb_accidents,
        AVG(CASE
            WHEN u.grav = 2 THEN 100
            WHEN u.grav = 3 THEN 10
            WHEN u.grav = 4 THEN 1
            ELSE 0
        END) as gravite_moyenne
    FROM ACCIDENT a
    INNER JOIN LIEUX l USING (num_acc)
    INNER JOIN USAGER u USING (num_acc)
    WHERE l.dep_code IS NOT NULL
    GROUP BY l.dep_code, l.dep_name
    HAVING COUNT(DISTINCT a.num_acc) >= 100  -- Échantillon significatif
    ORDER BY gravite_moyenne DESC
    LIMIT 10
)
ORDER BY categorie, nb_accidents DESC;



-- ============================================================================
