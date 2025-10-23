-- ============================================================================
-- REQUÊTES ANALYTIQUES - VERSION COMPLÈTE
-- Projet : Analyse des Accidents Corporels de la Circulation en France
-- ============================================================================
-- Ce fichier répond aux besoins KPI métier + analyses avancées
--
-- PARTIE 1 : KPI OPÉRATIONNELS ( requêtes)
--   Section 1 : Zones à risque ( requêtes)
--   Section 2 : Conditions de survenue ( requêtes)
--   Section 3 : Tendances temporelles ( requêtes)
--
-- PARTIE 2 : ANALYSES AVANCÉES 
--   Section 4 : Conditions à risque (analyse statistique)
--   Section 5 : Zones fréquentées vs accidents graves
--   Section 6 : Détection d'anomalies temporelles
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
    l.circ as regime_circulation,
    CASE l.circ
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
INNER JOIN LIEUX l USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
GROUP BY l.circ
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
    

-- 1.5.3 Par tracé en plan

-- 1.5.4 Par profil en long (déclivité)


-- ----------------------------------------------------------------------------

-- 1.6 KPI SECONDAIRE : Top 10 des régions avec le plus d'accidents mortels
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 1.7 KPI SECONDAIRE : Top 10 des communes avec le plus d'accidents mortels
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 1.8 KPI SECONDAIRE : % d'accidents mortels agglo VS non-agglo
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 1.9 KPI SECONDAIRE : Top des types de routes les plus mortelles
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------

-- 1.10 KPI SECONDAIRE : Top des typologies de voies les plus mortelles
-- ----------------------------------------------------------------------------


-- 1.10.1 Par régime de circulation (mortels)


-- 1.10.2 Par tracé en plan (mortels)



-- ============================================================================
-- SECTION 2 : ÉTUDIER LES CONDITIONS DE SURVENUE
-- ============================================================================

-- ----------------------------------------------------------------------------

-- 2.1 KPI PRIORITAIRE : Top des conditions météo les plus accidentogènes
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 2.2 KPI PRIORITAIRE : Top des conditions de voirie les plus accidentogènes
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 2.3 KPI PRIORITAIRE : Top des conditions de luminosité les plus accidentogènes
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 2.4 KPI PRIORITAIRE : Répartition des accidents par type de collision
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 2.5 KPI PRIORITAIRE : Répartition des accidents par type de véhicule
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 2.6 KPI PRIORITAIRE : Répartition des accidents par type d'usagers
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 2.7 KPI SECONDAIRE : Top des conditions météo les plus mortelles
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 2.8 KPI SECONDAIRE : Top des conditions de voirie les plus mortelles
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 2.9 KPI SECONDAIRE : Top des conditions de luminosité les plus mortelles
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 2.10 KPI SECONDAIRE : Types de collision les plus mortelles
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 2.11 KPI SECONDAIRE : Répartition des accidents mortels par type de véhicule
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 2.12 KPI SECONDAIRE : Répartition des accidents mortels par type d'usagers
-- ----------------------------------------------------------------------------




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
INNER JOIN DATE d USING (num_acc)
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
INNER JOIN DATE d USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE d.mois IS NOT NULL
GROUP BY d.mois
ORDER BY d.mois;

-- ----------------------------------------------------------------------------

-- 3.3 KPI PRIORITAIRE : Répartition par heure de la journée (toutes années)
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 3.4 KPI PRIORITAIRE : Nombre d'accidents par jour de la semaine
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 3.5 KPI SECONDAIRE : Nombre d'accidents mortels par années
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 3.6 KPI SECONDAIRE : Nombre d'accidents mortels par mois (toutes années)
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 3.7 KPI SECONDAIRE : Répartition accidents mortels par heure (toutes années)
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 3.8 KPI SECONDAIRE : Nombre d'accidents mortels par jour de la semaine
-- ----------------------------------------------------------------------------




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




-- ----------------------------------------------------------------------------

-- 4.3 Impact de la luminosité
-- ----------------------------------------------------------------------------





-- ============================================================================
-- SECTION 5 : ZONES FRÉQUENTÉES vs ACCIDENTS GRAVES
-- ============================================================================
-- Objectif : Déterminer si les zones les plus fréquentées ont plus d'accidents graves
--            ou simplement plus d'accidents au total
-- ============================================================================

-- ----------------------------------------------------------------------------

-- 5.1 Analyse par département (volume vs gravité)
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 5.2 Corrélation statistique entre volume et gravité
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 5.3 Top 10 départements les plus fréquentés vs Top 10 les plus dangereux
-- ----------------------------------------------------------------------------





-- ============================================================================
-- SECTION 6 : DÉTECTION D'ANOMALIES TEMPORELLES
-- ============================================================================
-- Objectif : Identifier les semaines où le nombre d'accidents s'écarte fortement
--            de la moyenne (détection d'anomalies temporelles)
-- ============================================================================

-- ----------------------------------------------------------------------------

-- 6.1 Analyse des semaines avec z-score (écart normalisé)
-- ----------------------------------------------------------------------------




-- ----------------------------------------------------------------------------

-- 6.2 Analyse des pics d'accidents par période de l'année
-- ----------------------------------------------------------------------------





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
    AND tablename IN ('ACCIDENT', 'VEHICULE', 'USAGER', 'LIEUX', 'DATE')
ORDER BY tablename, indexname;

-- ----------------------------------------------------------------------------

-- 7.3 Test de performance : EXPLAIN ANALYZE
-- ----------------------------------------------------------------------------


-- Test 1 : Requête avec jointure sur département


-- Test 2 : Requête temporelle avec jointure sur DATE


-- Test 3 : Requête complexe avec multiples jointures


-- ----------------------------------------------------------------------------

-- 7.5 Suggestions d'index (basées sur les requêtes précédentes)
-- ----------------------------------------------------------------------------


-- Commandes pour créer les index recommandés :

-- Index sur les clés étrangères (num_acc) pour accélérer les jointures
-- CREATE INDEX IF NOT EXISTS idx_vehicule_num_acc ON VEHICULE(num_acc);
-- CREATE INDEX IF NOT EXISTS idx_usager_num_acc ON USAGER(num_acc);
-- CREATE INDEX IF NOT EXISTS idx_lieux_num_acc ON LIEUX(num_acc);
-- CREATE INDEX IF NOT EXISTS idx_date_num_acc ON DATE(num_acc);

-- Index sur les colonnes de filtrage fréquentes


-- Index composites pour les requêtes complexes



-- ============================================================================
-- BONUS : REQUÊTES UTILES POUR L'ANALYSE
-- ============================================================================

-- ----------------------------------------------------------------------------

-- Vue d'ensemble rapide du dataset
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------

-- Répartition par gravité des usagers
-- ----------------------------------------------------------------------------



-- ============================================================================
-- Fin du fichier requetes.sql
-- ============================================================================
