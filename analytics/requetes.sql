-- ============================================================================
-- REQUÊTES ANALYTIQUES - VERSION COMPLÈTE
-- Projet : Analyse des Accidents Corporels de la Circulation en France
-- ============================================================================
-- Ce fichier répond aux besoins KPI métier + analyses avancées
--
-- PARTIE 1 : KPI OPÉRATIONNELS ( 34 requêtes)
--   Section 1 : Zones à risque (14 requêtes)
--   Section 2 : Conditions de survenue (12 requêtes)
--   Section 3 : Tendances temporelles ( 8 requêtes)
--
-- PARTIE 2 : ANALYSES AVANCÉES 
--   Section 4 : Conditions à risque (analyse statistique) -> 3 requêtes
--   Section 5 : Zones fréquentées vs accidents graves -> 3 requêtes
--   Section 6 : Détection d'anomalies temporelles -> 2 requêtes
--   Section 7 : Optimisation (partitionnement & indexation)
--
-- BONUS : Vues d'ensemble et statistiques
-- ============================================================================

\c accidents_db

-- ============================================================================
-- PARTIE 1 : KPI OPÉRATIONNELS
-- ============================================================================

-- ============================================================================
-- SECTION 1 : CONNAÎTRE LES ZONES À RISQUE
-- ============================================================================

-- ----------------------------------------------------------------------------

-- 1.1 KPI PRIORITAIRE : Top 10 des régions les plus accidentogènes
-- ----------------------------------------------------------------------------


SELECT
    l.reg_code,
    l.reg_name,
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 1 THEN 1 ELSE 0 END) as nb_indemnes,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as nb_blesses_hospitalises,
    SUM(CASE WHEN u.grav = 4 THEN 1 ELSE 0 END) as nb_blesses_legers,

    -- Pourcentages
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as pct_accidents_mortels,

    -- Classement
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT a.num_acc) DESC) as rang

FROM ACCIDENT a
INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE l.reg_code IS NOT NULL
GROUP BY l.reg_code, l.reg_name
ORDER BY nb_accidents DESC
LIMIT 10;

-- ----------------------------------------------------------------------------

-- 1.2 KPI PRIORITAIRE : Top 10 des communes les plus accidentogènes
-- ----------------------------------------------------------------------------


SELECT
    l.com_code,
    l.com_name,
    l.dep_code,
    l.dep_name,
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as nb_blesses_hospitalises,

    -- Pourcentages
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as pct_accidents_mortels,

    -- Classement
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT a.num_acc) DESC) as rang

FROM ACCIDENT a
INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE l.com_code IS NOT NULL
GROUP BY l.com_code, l.com_name, l.dep_code, l.dep_name
ORDER BY nb_accidents DESC
LIMIT 10;

-- ----------------------------------------------------------------------------

-- 1.3 KPI PRIORITAIRE : % accidents agglo vs non-agglo
-- ----------------------------------------------------------------------------


SELECT
    a.agg as code_agglo,
    CASE a.agg
        WHEN 1 THEN 'Hors agglomération'
        WHEN 2 THEN 'En agglomération'
        ELSE 'Non renseigné'
    END as libelle_agglo,

    -- Comptages
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT u.id_personne) as nb_personnes_impliquees,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    SUM(CASE WHEN u.grav = 3 THEN 1 ELSE 0 END) as nb_blesses_hospitalises,
    SUM(CASE WHEN u.grav = 4 THEN 1 ELSE 0 END) as nb_blesses_legers,

    -- Pourcentages par rapport au total
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
          SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          SUM(SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END)) OVER (), 2) as pct_tues,

    -- Taux de mortalité dans chaque catégorie
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.agg
ORDER BY a.agg;

-- ----------------------------------------------------------------------------

-- 1.4 KPI PRIORITAIRE : Top des types de routes les plus accidentogènes
-- ----------------------------------------------------------------------------


SELECT
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
INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
GROUP BY l.catr
ORDER BY nb_accidents DESC;

-- ----------------------------------------------------------------------------

-- 1.5 KPI PRIORITAIRE : Top des typologies de voies accidentogènes
-- ----------------------------------------------------------------------------


-- 1.5.1 Par régime de circulation
SELECT
    a.circ as regime_circulation,
    CASE a.circ
        WHEN 1 THEN 'À sens unique'
        WHEN 2 THEN 'Bidirectionnelle'
        WHEN 3 THEN 'À chaussées séparées'
        WHEN 4 THEN 'Avec voies d''affectation variable'
        ELSE 'Non renseigné'
    END as libelle_circulation,

    COUNT(DISTINCT a.num_acc) as nb_accidents,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
          SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct

FROM ACCIDENT a
-- INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.circ
ORDER BY nb_accidents DESC;

-- 1.5.2 Par voie réservée
SELECT
    l.vsop as voir_reservee,
    CASE l.vsop
        WHEN 1 THEN 'Piste cyclable'
        WHEN 2 THEN 'Bande cyclable'
        WHEN 3 THEN 'Voie réservée'
        ELSE 'Pas de voie réservée'
    END as libelle_voie_reservee,
    
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
         SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEn 1 ELSE 0 END) / 
         NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct

FROM ACCIDENT a
INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
GROUP BY l.vosp
ORDER BY nb_accidents DESC;


-- 1.5.3 Par tracé en plan

SELECT
    a.plan as code_trace_plan,
    CASE a.plan
        WHEN 1 THEN 'Partie rectiligne'
        WHEN 2 THEN 'En courbe à gauche'
        WHEN 3 THEN 'En courbe à droite'
        WHEN 4 THEN 'En S'
        ELSE 'Non renseigné'
    END as libelle_trace_plan,

    COUNT(DISTINCT a.num_acc) as nb_accidents,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) / 
            SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.plan 
ORDER BY nb_accidents DESC;


-- 1.5.4 Par profil en prof (déclivité)
SELECT
    a.prof as code_profil,
    CASE l.prof
        WHEN 1 THEN 'Plat'
        WHEN 2 THEN 'Pente'
        WHEN 3 THEN 'Sommet de côte'
        WHEN 4 THEN 'Bas de côte'
        ELSE 'Non renseigné'
    END as libelle_profil,

    COUNT(DISTINCT a.num_acc) as nb_accidents,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    ROUND(100.0 * COUNT(DISTINCT a.num_acc) /
          SUM(COUNT(DISTINCT a.num_acc)) OVER (), 2) as pct_accidents,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.prof
ORDER BY nb_accidents DESC;


-- ----------------------------------------------------------------------------

-- 1.6 KPI SECONDAIRE : Top 10 des régions avec le plus d'accidents mortels
-- ----------------------------------------------------------------------------
SELECT
    l.reg_code,
    l.reg_name,
    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as pct_accidents_mortels,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct,

    -- Classement
    DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) DESC) as rang

FROM ACCIDENT a
INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE l.reg_code IS NOT NULL
GROUP BY l.reg_code, l.reg_name
ORDER BY nb_tues DESC
LIMIT 10;


-- ----------------------------------------------------------------------------

-- 1.7 KPI SECONDAIRE : Top 10 des communes avec le plus d'accidents mortels
-- ----------------------------------------------------------------------------

SELECT
    l.com_code,
    l.com_name,
    l.dep_code,
    l.dep_name,
    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as pct_accidents_mortels,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(DISTINCT u.id_personne), 0), 2) as taux_mortalite_pct,

    -- Classement
    DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) DESC) as rang

FROM ACCIDENT a
INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE l.com_code IS NOT NULL
GROUP BY l.com_code, l.com_name, l.dep_code, l.dep_name
ORDER BY nb_tues DESC
LIMIT 10;


-- ----------------------------------------------------------------------------

-- 1.8 KPI SECONDAIRE : % d'accidents mortels agglo VS non-agglo
-- ----------------------------------------------------------------------------

SELECT
    a.agg as code_agglo,
    CASE a.agg
        WHEN 1 THEN 'Hors agglomération'
        WHEN 2 THEN 'En agglomération'
        ELSE 'Non renseigné'
    END as libelle_agglo,

    -- Accidents mortels
    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels,
    ROUND(100.0 * SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) /
          SUM(SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END)) OVER (), 2) as pct_tues,

    -- Taux de mortalité dans chaque catégorie
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as taux_accidents_mortels_pct

FROM ACCIDENT a
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.agg
ORDER BY a.agg;


-- ----------------------------------------------------------------------------

-- 1.9 KPI SECONDAIRE : Top des types de routes les plus mortelles
-- ----------------------------------------------------------------------------

SELECT
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

    -- Accidents mortels
    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    COUNT(DISTINCT a.num_acc) as nb_accidents_total,

    -- Pourcentages
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          NULLIF(COUNT(DISTINCT a.num_acc), 0), 2) as taux_accidents_mortels_pct,

    -- Classement
    DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) DESC) as rang

FROM ACCIDENT a
INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
GROUP BY l.catr
ORDER BY nb_tues DESC;

-- ----------------------------------------------------------------------------

-- 1.10 KPI SECONDAIRE : Top des typologies de voies les plus mortelles
-- ----------------------------------------------------------------------------


-- 1.10.1 Par régime de circulation (mortels)
SELECT
    a.circ as code_circulation,
    CASE a.circ
        WHEN 1 THEN 'À sens unique'
        WHEN 2 THEN 'Bidirectionnelle'
        WHEN 3 THEN 'À chaussées séparées'
        WHEN 4 THEN 'Avec voies d''affectation variable'
        ELSE 'Non renseigné'
    END as libelle_circulation,

    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels

FROM ACCIDENT a
--INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.circ
ORDER BY nb_tues DESC;

-- 1.10.2 Par tracé en plan (mortels)
SELECT
    a.plan as code_trace_plan,
    CASE a.plan
        WHEN 1 THEN 'Partie rectiligne'
        WHEN 2 THEN 'En courbe à gauche'
        WHEN 3 THEN 'En courbe à droite'
        WHEN 4 THEN 'En S'
        ELSE 'Non renseigné'
    END as libelle_trace_plan,

    COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) as nb_accidents_mortels,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END) /
          SUM(COUNT(DISTINCT CASE WHEN u.grav = 2 THEN a.num_acc END)) OVER (), 2) as pct_accidents_mortels

FROM ACCIDENT a
--INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
GROUP BY a.plan
ORDER BY nb_tues DESC;


-- ============================================================================
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
-- SECTION 7 : OPTIMISATION - PARTITIONNEMENT & INDEXATION
-- ============================================================================
-- Objectif : Démontrer les gains de performance grâce au partitionnement
--            et à l'indexation
-- ============================================================================

-- ----------------------------------------------------------------------------

-- 7.1 Informations sur le partitionnement (si implémenté)
-- ----------------------------------------------------------------------------


-- Vue d'ensemble des partitions


-- ----------------------------------------------------------------------------

-- 7.2 Liste des index créés
-- ----------------------------------------------------------------------------


SELECT
    schemaname,
    tablename,
    indexname,
    indexdef,
    pg_size_pretty(pg_relation_size(indexrelid)) AS taille_index
FROM pg_indexes
WHERE schemaname = 'public'
    AND tablename IN ('ACCIDENT', 'VEHICULE', 'USAGER', 'LIEUX', 'DATE_ACCIDENT')
ORDER BY tablename, indexname;

-- ----------------------------------------------------------------------------

-- 7.3 Test de performance : EXPLAIN ANALYZE
-- ----------------------------------------------------------------------------


-- Test 1 : Requête avec jointure sur département

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    l.dep_code,
    l.dep_name,
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
WHERE l.dep_code = '75'  -- Paris
GROUP BY l.dep_code, l.dep_name;

-- Test 2 : Requête temporelle avec jointure sur DATE

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    d.an as annee,
    d.mois,
    COUNT(DISTINCT a.num_acc) as nb_accidents
FROM ACCIDENT a
INNER JOIN DATE_ACCIDENT d USING (num_acc)
WHERE d.an BETWEEN 2020 AND 2023
GROUP BY d.an, d.mois
ORDER BY d.an, d.mois;

-- Test 3 : Requête complexe avec multiples jointures

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    l.dep_code,
    a.lum,
    a.atm,
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues
FROM ACCIDENT a
INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
INNER JOIN DATE_ACCIDENT d USING (num_acc)
WHERE d.an = 2023
    AND l.dep_code IN ('75', '69', '13', '92', '93')
GROUP BY l.dep_code, a.lum, a.atm
ORDER BY nb_accidents DESC;

-- ───────────────────────────────────────────────────────────────────────────
-- 7.4 Statistiques d'utilisation des index
-- ───────────────────────────────────────────────────────────────────────────

SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as nb_utilisations,
    idx_tup_read as nb_tuples_lus,
    idx_tup_fetch as nb_tuples_recuperes,
    pg_size_pretty(pg_relation_size(indexrelid)) as taille_index
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
    AND tablename IN ('ACCIDENT', 'VEHICULE', 'USAGER', 'LIEUX', 'DATE_ACCIDENT')
ORDER BY idx_scan DESC, pg_relation_size(indexrelid) DESC;

-- ----------------------------------------------------------------------------

-- 7.5 Suggestions d'index (basées sur les requêtes précédentes)
-- ----------------------------------------------------------------------------


-- Commandes pour créer les index recommandés :

-- Index sur les clés étrangères (num_acc) pour accélérer les jointures
-- CREATE INDEX IF NOT EXISTS idx_vehicule_num_acc ON VEHICULE(num_acc);
-- CREATE INDEX IF NOT EXISTS idx_usager_num_acc ON USAGER(num_acc);
-- CREATE INDEX IF NOT EXISTS idx_lieux_num_acc ON LIEUX(num_acc);
-- CREATE INDEX IF NOT EXISTS idx_date_num_acc ON DATE_ACCIDENT(num_acc);

-- Index sur les colonnes de filtrage fréquentes


-- Index composites pour les requêtes complexes



-- ============================================================================
-- BONUS : REQUÊTES UTILES POUR L'ANALYSE
-- ============================================================================

-- ----------------------------------------------------------------------------

-- Vue d'ensemble rapide du dataset
-- ----------------------------------------------------------------------------

SELECT
    'Période couverte' as metrique,
    MIN(make_date(d.an, d.mois, d.jour))::TEXT || ' - ' || MAX(make_date(d.an, d.mois, d.jour))::TEXT as valeur
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
    'Nombre total de véhicules impliqués',
    COUNT(*)::TEXT
FROM VEHICULE
UNION ALL
SELECT
    'Nombre total de tués',
    SUM(CASE WHEN grav = 2 THEN 1 ELSE 0 END)::TEXT
FROM USAGER
UNION ALL
SELECT
    'Nombre total de blessés hospitalisés',
    SUM(CASE WHEN grav = 3 THEN 1 ELSE 0 END)::TEXT
FROM USAGER
UNION ALL
SELECT
    'Nombre de régions concernées',
    COUNT(DISTINCT reg_code)::TEXT
FROM LIEUX
WHERE reg_code IS NOT NULL
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

-- ----------------------------------------------------------------------------

-- Répartition par gravité des usagers
-- ----------------------------------------------------------------------------

SELECT
    grav as code_gravite,
    CASE grav
        WHEN 1 THEN 'Indemne'
        WHEN 2 THEN 'Tué'
        WHEN 3 THEN 'Blessé hospitalisé'
        WHEN 4 THEN 'Blessé léger'
        ELSE 'Non renseigné'
    END as libelle_gravite,
    COUNT(*) as nombre,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pourcentage
FROM USAGER
GROUP BY grav
ORDER BY grav;

-- ============================================================================
-- Fin du fichier requetes.sql
-- ============================================================================
