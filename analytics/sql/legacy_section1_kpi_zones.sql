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
