-- SECTION 4 : CONDITIONS À RISQUE (Analyse statistique avancée)
-- ============================================================================
-- Objectif : Identifier les combinaisons de conditions (météo + luminosité + type de route)
--            qui présentent un risque significativement supérieur à la moyenne nationale
-- ============================================================================

-- ----------------------------------------------------------------------------

-- 4.1 Analyse des combinaisons de conditions les plus dangereuses
-- ----------------------------------------------------------------------------
-- zscore : mesure combien d’écarts-types une valeur s’écarte de la moyenne
-- (valeur obs - moyenne pop) / ecart-type pop (voir visualisation courbe de Gaus)

WITH statitstiques_nationnales As (
    -- Calcul de la moyenne nationnale
    -- Indicateurs de gravité (pondération : tué=100, blessé hospitalisé=10, blessé léger=1)
    SELECT
        COUNT(DISTINCT a.num_acc) as nb_accidents_total,
        COUNT(*) ad nb_victimes_total,
        SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as total_tues,
        SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as total_blesses_hospitalises,
        AVG(CASE
            WHEN u.grav = 2 THEN 100 -- Tué
            WHEN u.grav = 3 THEN 10 -- Blessé hospitalisé
            WHEN u.grav = 4 THEN 1 -- Blessé léger
            ELse 0
        END) as gravite_moyenne_nationale,
        STDDEV(CASE
            WHEN u.grav = 2 THEN 100
            WHEN u.grav = 3 THEN 10
            WHEN u.grav = 4 THEN 1
            ELSE 0
        END) as ecart_type_gravite
    FROM ACCIDENT a
    INNER JOIN USAGER u USING (num_acc)
),
analyse_conditions AS (
    -- Analyse par combinaison de conditions
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

        a.lum as code_lumiere,
        CASE a.lum
            WHEN 1 THEN 'Plein jour'
            WHEN 2 THEN 'Crépuscule ou aube'
            WHEN 3 THEN 'Nuit sans éclairage public'
            WHEN 4 THEN 'Nuit avec éclairage public non allumé'
            WHEN 5 THEN 'Nuit avec éclairage public allumé'
            ELSE 'Non renseigné'
        END as libelle_lumiere,

        l.catr as code_categorie_route,
        CASE l.catr
            WHEN 1 THEN 'Autoroute'
            WHEN 2 THEN 'Route nationale'
            WHEN 3 THEN 'Route départementale'
            WHEN 4 THEN 'Voie communale'
            WHEN 5 THEN 'Hors réseau public'
            WHEN 6 THEN 'Parc de stationnement'
            WHEN 7 THEN 'Routes de métropole urbaine'
            WHEN 9 THEN 'Autre'
            ELSE 'Non renseigné'
        END as libelle_categorie_route,

        -- Comptages
        COUNT(DISTINCT a.num_acc) as nb_accidents,
        COUNT(DISTINCT u.id_personne) as nb_impliques,
        SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
        SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as nb_blesses_hospitalises,
        SUM(CASE WHEN u.grav = 4 THEN 1 ELSE 0 END) as nb_blesses_legers,

        -- Indicateurs de gravité (pondération : tué=100, blessé hospitalisé=10, blessé léger=1)
        AVG(CASE
            WHEN u.grav = 2 THEN 100
            WHEN u.grav = 3 THEN 10
            WHEN u.grav = 4 THEN 1
            ELSE 0
        END) as gravite_moyenne,

        MAX(CASE
            WHEN u.grav = 2 THEN 100
            WHEN u.grav = 3 THEN 10
            WHEN u.grav = 4 THEN 1
            ELSE 0
        END) as gravite_max,

        -- Taux de mortalité et gravité
        ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
              NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite,
        ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
              NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as pct_accidents_mortels,
        ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav IN (2,3) THEN a.num_acc END) /
              NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as pct_accidents_graves

    FROM ACCIDENT a
    INNER JOIN USAGER u USING (num_acc)
    INNER JOIN LIEUX l USING (num_acc)

-- Filtrer pour avoir des échantillons statistiquement significatifs
    GROUP BY a.atm, a.lum, l.catr
    HAVING COUNT(DISTINCT a.num_acc) >= 100  -- Au moins 100 accidents pour être significatif
)
SELECT
    ac.libelle_meteo,
    ac.libelle_lumiere,
    ac.libelle_categorie_route,
    ac.nb_accidents,
    ac.nb_tues,
    ac.nb_blesses_hospitalises,
    ac.gravite_moyenne,
    sn.gravite_moyenne_nationale,

    -- Écart par rapport à la moyenne nationale
    ROUND(ac.gravite_moyenne - sn.gravite_moyenne_nationale, 2) as ecart_gravite,
    ROUND((ac.gravite_moyenne - sn.gravite_moyenne_nationale) /
          NULLIF(sn.ecart_type_gravite, 0), 2) as z_score,

    ac.taux_mortalite,
    ac.pct_accidents_mortels,
    ac.pct_accidents_graves,

    -- Interprétation
    CASE
        WHEN (ac.gravite_moyenne - sn.gravite_moyenne_nationale) /
             NULLIF(sn.ecart_type_gravite, 0) > 2 THEN 'RISQUE TRÈS ÉLEVÉ'
        WHEN (ac.gravite_moyenne - sn.gravite_moyenne_nationale) /
             NULLIF(sn.ecart_type_gravite, 0) > 1 THEN 'RISQUE ÉLEVÉ'
        WHEN (ac.gravite_moyenne - sn.gravite_moyenne_nationale) /
             NULLIF(sn.ecart_type_gravite, 0) > 0 THEN 'RISQUE MODÉRÉ'
        ELSE 'RISQUE FAIBLE'
    END as niveau_risque

FROM analyse_conditions ac
CROSS JOIN statistiques_nationales sn

-- Ordonner par gravité moyenne décroissante
ORDER BY ac.gravite_moyenne DESC, ac.nb_accidents DESC
LIMIT 30;

-- ----------------------------------------------------------------------------

-- 4.2 Focus sur les conditions météo défavorables
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
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    AVG(CASE
        WHEN u.grav = 2 THEN 100
        WHEN u.grav = 3 THEN 10
        WHEN u.grav = 4 THEN 1
        ELSE 0
    END) as gravite_moyenne,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite
FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.atm
ORDER BY gravite_moyenne DESC;


-- ----------------------------------------------------------------------------

-- 4.3 Impact de la luminosité
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
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    AVG(CASE
        WHEN u.grav = 2 THEN 100
        WHEN u.grav = 3 THEN 10
        WHEN u.grav = 4 THEN 1
        ELSE 0
    END) as gravite_moyenne,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as pct_accidents_mortels
FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.lum
ORDER BY gravite_moyenne DESC;



-- ============================================================================
