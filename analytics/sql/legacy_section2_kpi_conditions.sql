-- SECTION 2 : ÉTUDIER LES CONDITIONS DE SURVENUE
-- ============================================================================

-- ----------------------------------------------------------------------------

-- 2.1 KPI PRIORITAIRE : Top des conditions météo les plus accidentogènes
-- ----------------------------------------------------------------------------

SELECT
    a.atm as code_meteo,
    CASE a.atm
        WHEN 1 THEN 'Normale'
        WHEN 2 THEN 'Pluie légère'
        WHEN 3 THEN 'Pluie forte'
        WHEN 4 THEN 'Neige - grêle'
        WHEN 5 THEN 'Brouillard - fumée'
        WHEN 6 THEN 'Vent fort - tempête'
        WHEN 7 THEN 'Temps éblouissant'
        WHEN 8 THEN 'Temps couvert'
        WHEN 9 THEN 'Autre'
        ELSE 'Non renseigné'
    END as libelle_meteo,

    -- Comptages
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as nb_blesses_hospitalises,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
          SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct,

    -- Classement
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT a.num_acc) DESC) as rang

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.atm
ORDER BY nb_accidents DESC;


-- ----------------------------------------------------------------------------

-- 2.2 KPI PRIORITAIRE : Top des conditions de voirie les plus accidentogènes
-- ----------------------------------------------------------------------------

SELECT
    a.surf as code_surface,
    CASE a.surf
        WHEN 1 THEN 'Normale'
        WHEN 2 THEN 'Mouillée'
        WHEN 3 THEN 'Flaques'
        WHEN 4 THEN 'Inondée'
        WHEN 5 THEN 'Enneigée'
        WHEN 6 THEN 'Boue'
        WHEN 7 THEN 'Verglacée'
        WHEN 8 THEN 'Corps gras - huile'
        WHEN 9 THEN 'Autre'
        ELSE 'Non renseigné'
    END as libelle_surface,

    -- Comptages
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as nb_blesses_hospitalises,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
          SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct,

    -- Classement
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT a.num_acc) DESC) as rang

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.surf
ORDER BY nb_accidents DESC;


-- ----------------------------------------------------------------------------

-- 2.3 KPI PRIORITAIRE : Top des conditions de luminosité les plus accidentogènes
-- ----------------------------------------------------------------------------

SELECT
    a.lum as code_lumiere,
    CASE a.lum
        WHEN 1 THEN 'Plein jour'
        WHEN 2 THEN 'Crépuscule ou aube'
        WHEN 3 THEN 'Nuit sans éclairage public'
        WHEN 4 THEN 'Nuit avec éclairage public non allumé'
        WHEN 5 THEN 'Nuit avec éclairage public allumé'
        ELSE 'Non renseigné'
    END as libelle_lumiere,

    -- Comptages
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as nb_blesses_hospitalises,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
          SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct,

    -- Classement
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT a.num_acc) DESC) as rang

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.lum
ORDER BY nb_accidents DESC;


-- ----------------------------------------------------------------------------

-- 2.4 KPI PRIORITAIRE : Répartition des accidents par type de collision
-- ----------------------------------------------------------------------------

SELECT
    a.col as code_collision,
    CASE a.col
        WHEN 1 THEN 'Deux véhicules - frontale'
        WHEN 2 THEN 'Deux véhicules - par l''arrière'
        WHEN 3 THEN 'Deux véhicules - par le côté'
        WHEN 4 THEN 'Trois véhicules et plus - en chaîne'
        WHEN 5 THEN 'Trois véhicules et plus - collisions multiples'
        WHEN 6 THEN 'Autre collision'
        WHEN 7 THEN 'Sans collision'
        ELSE 'Non renseigné'
    END as libelle_collision,

    -- Comptages
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as nb_blesses_hospitalises,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
          SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct,

    -- Classement
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT a.num_acc) DESC) as rang

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.col
ORDER BY nb_accidents DESC;


-- ----------------------------------------------------------------------------

-- 2.5 KPI PRIORITAIRE : Répartition des accidents par type de véhicule
-- ----------------------------------------------------------------------------

SELECT
    v.catv as code_categorie_vehicule,
    -- Note: Les codes véhicules varient selon les années.
    CASE
        WHEN v.catv IN (1, 2, 3, 4, 5, 6, 7) THEN 'Véhicule léger'
        WHEN v.catv IN (10, 11, 12, 13, 14, 15, 16, 17) THEN 'Véhicule utilitaire'
        WHEN v.catv IN (20, 21) THEN 'Poids lourd'
        WHEN v.catv IN (30, 31, 32, 33, 34, 35, 36, 37, 38) THEN 'Transports en commun'
        WHEN v.catv IN (40, 41, 42, 43) THEN 'Train'
        WHEN v.catv IN (50, 60) THEN 'Deux-roues motorisé'
        WHEN v.catv IN (80, 81, 82, 83) THEN 'Vélo / Mobilité douce'
        WHEN v.catv = 99 THEN 'Autre véhicule'
        ELSE 'Non renseigné'
    END as categorie_vehicule_groupe,

    -- Comptages
    COUNT(DISTINCT v.id_vehicule) as nb_vehicules,
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT v.id_vehicule) /
          SUM(COUNT(DISTINCT v.id_vehicule)) OVER (), 2) as pct_vehicules,
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
          SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents

FROM ACCIDENT a
INNER JOIN VEHICULE v USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
GROUP BY v.catv
ORDER BY nb_vehicules DESC;


-- ----------------------------------------------------------------------------

-- 2.6 KPI PRIORITAIRE : Répartition des accidents par type d'usagers
-- ----------------------------------------------------------------------------

SELECT
    u.catu as code_categorie_usager,
    CASE u.catu
        WHEN 1 THEN 'Conducteur'
        WHEN 2 THEN 'Passager'
        WHEN 3 THEN 'Piéton'
        WHEN 4 THEN 'Piéton en roller ou trottinette'
        ELSE 'Non renseigné'
    END as libelle_categorie_usager,

    -- Comptages
    COUNT(DISTINCT u.id_personne) as nb_personnes,
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    SUM(CASE WHEN u.grav = 1 THEN 1 ELSE 0 END) as nb_indemnes,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as nb_blesses_hospitalises,
    SUM(CASE WHEN u.grav = 4 THEN 1 ELSE 0 END) as nb_blesses_legers,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT u.id_personne) /
          SUM(COUNT(DISTINCT u.id_personne)) OVER (), 2) as pct_usagers,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct,

    -- Classement
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT u.id_personne) DESC) as rang

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY u.catu
ORDER BY nb_personnes DESC;


-- ----------------------------------------------------------------------------

-- 2.7 KPI SECONDAIRE : Top des conditions météo les plus mortelles
-- ----------------------------------------------------------------------------

SELECT
    a.atm as code_meteo,
    CASE a.atm
        WHEN 1 THEN 'Normale'
        WHEN 2 THEN 'Pluie légère'
        WHEN 3 THEN 'Pluie forte'
        WHEN 4 THEN 'Neige - grêle'
        WHEN 5 THEN 'Brouillard - fumée'
        WHEN 6 THEN 'Vent fort - tempête'
        WHEN 7 THEN 'Temps éblouissant'
        WHEN 8 THEN 'Temps couvert'
        WHEN 9 THEN 'Autre'
        ELSE 'Non renseigné'
    END as libelle_meteo,

    -- Accidents mortels
    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as taux_accidents_mortels_pct

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.atm
ORDER BY nb_tues DESC;


-- ----------------------------------------------------------------------------

-- 2.8 KPI SECONDAIRE : Top des conditions de voirie les plus mortelles
-- ----------------------------------------------------------------------------

SELECT
    a.surf as code_surface,
    CASE a.surf
        WHEN 1 THEN 'Normale'
        WHEN 2 THEN 'Mouillée'
        WHEN 3 THEN 'Flaques'
        WHEN 4 THEN 'Inondée'
        WHEN 5 THEN 'Enneigée'
        WHEN 6 THEN 'Boue'
        WHEN 7 THEN 'Verglacée'
        WHEN 8 THEN 'Corps gras - huile'
        WHEN 9 THEN 'Autre'
        ELSE 'Non renseigné'
    END as libelle_surface,

    -- Accidents mortels
    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as taux_accidents_mortels_pct

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.surf
ORDER BY nb_tues DESC;


-- ----------------------------------------------------------------------------

-- 2.9 KPI SECONDAIRE : Top des conditions de luminosité les plus mortelles
-- ----------------------------------------------------------------------------

SELECT
    a.lum as code_lumiere,
    CASE a.lum
        WHEN 1 THEN 'Plein jour'
        WHEN 2 THEN 'Crépuscule ou aube'
        WHEN 3 THEN 'Nuit sans éclairage public'
        WHEN 4 THEN 'Nuit avec éclairage public non allumé'
        WHEN 5 THEN 'Nuit avec éclairage public allumé'
        ELSE 'Non renseigné'
    END as libelle_lumiere,

    -- Accidents mortels
    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as taux_accidents_mortels_pct

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.lum
ORDER BY nb_tues DESC;


-- ----------------------------------------------------------------------------

-- 2.10 KPI SECONDAIRE : Types de collision les plus mortelles
-- ----------------------------------------------------------------------------

SELECT
    a.col as code_collision,
    CASE a.col
        WHEN 1 THEN 'Deux véhicules - frontale'
        WHEN 2 THEN 'Deux véhicules - par l''arrière'
        WHEN 3 THEN 'Deux véhicules - par le côté'
        WHEN 4 THEN 'Trois véhicules et plus - en chaîne'
        WHEN 5 THEN 'Trois véhicules et plus - collisions multiples'
        WHEN 6 THEN 'Autre collision'
        WHEN 7 THEN 'Sans collision'
        ELSE 'Non renseigné'
    END as libelle_collision,

    -- Accidents mortels
    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as taux_accidents_mortels_pct

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.col
ORDER BY nb_tues DESC;


-- ----------------------------------------------------------------------------

-- 2.11 KPI SECONDAIRE : Répartition des accidents mortels par type de véhicule
-- ----------------------------------------------------------------------------
-- 🚨 mensongère???? car pas de lien usager - vehicule
SELECT
    v.catv as code_categorie_vehicule,
    CASE
        WHEN v.catv IN (1, 2, 3, 4, 5, 6, 7) THEN 'Véhicule léger'
        WHEN v.catv IN (10, 11, 12, 13, 14, 15, 16, 17) THEN 'Véhicule utilitaire'
        WHEN v.catv IN (20, 21) THEN 'Poids lourd'
        WHEN v.catv IN (30, 31, 32, 33, 34, 35, 36, 37, 38) THEN 'Transports en commun'
        WHEN v.catv IN (40, 41, 42, 43) THEN 'Train'
        WHEN v.catv IN (50, 60) THEN 'Deux-roues motorisé'
        WHEN v.catv IN (80, 81, 82, 83) THEN 'Vélo / Mobilité douce'
        WHEN v.catv = 99 THEN 'Autre véhicule'
        ELSE 'Non renseigné'
    END as categorie_vehicule_groupe,

    -- Accidents mortels
    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels

FROM ACCIDENT a
INNER JOIN VEHICULE v USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
GROUP BY v.catv
ORDER BY nb_tues DESC;


-- ----------------------------------------------------------------------------

-- 2.12 KPI SECONDAIRE : Répartition des accidents mortels par type d'usagers
-- ----------------------------------------------------------------------------

SELECT
    u.catu as code_categorie_usager,
    CASE u.catu
        WHEN 1 THEN 'Conducteur'
        WHEN 2 THEN 'Passager'
        WHEN 3 THEN 'Piéton'
        WHEN 4 THEN 'Piéton en roller ou trottinette'
        ELSE 'Non renseigné'
    END as libelle_categorie_usager,

    -- Accidents mortels
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT u.id_personne) as nb_personnes_total,

    -- Pourcentages
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          SUM(SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END)) OVER (), 2) as pct_tues,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY u.catu
ORDER BY nb_tues DESC;



-- ============================================================================
