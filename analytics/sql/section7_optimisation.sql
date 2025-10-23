-- ============================================================================
-- SECTION 7 : OPTIMISATION - PARTITIONNEMENT & INDEXATION
-- ============================================================================
-- Objectif : Analyser la volumétrie, fournir des templates de partitionnement
--            et recommander des index pour optimiser les performances
--
-- Contenu :
--   7.0 : Analyse de volumétrie (décision partitionnement)
--   7.1 : Templates de partitionnement par année (COMMENTÉS)
--   7.2 : Index recommandés sur tables sources
--   7.3 : Tests de performance EXPLAIN ANALYZE
--   7.4 : Statistiques d'utilisation des index
-- ============================================================================

\echo '========================================'
\echo 'SECTION 7 : OPTIMISATION'
\echo '========================================'
\echo ''

-- ============================================================================
-- 7.0 : ANALYSE DE VOLUMÉTRIE
-- ============================================================================

\echo '──────────────────────────────────────────'
\echo '7.0 : Analyse de volumétrie'
\echo '──────────────────────────────────────────'
\echo ''

-- Comptage par table
\echo 'Volumétrie globale :'
\echo ''

SELECT
    'ACCIDENT' as table_name,
    COUNT(*) as nb_lignes,
    pg_size_pretty(pg_total_relation_size('ACCIDENT')) as taille_totale
FROM ACCIDENT
UNION ALL
SELECT
    'USAGER',
    COUNT(*),
    pg_size_pretty(pg_total_relation_size('USAGER'))
FROM USAGER
UNION ALL
SELECT
    'VEHICULE',
    COUNT(*),
    pg_size_pretty(pg_total_relation_size('VEHICULE'))
FROM VEHICULE
UNION ALL
SELECT
    'LIEUX',
    COUNT(*),
    pg_size_pretty(pg_total_relation_size('LIEUX'))
FROM LIEUX
UNION ALL
SELECT
    'DATE_ACCIDENT',
    COUNT(*),
    pg_size_pretty(pg_total_relation_size('DATE_ACCIDENT'))
FROM DATE_ACCIDENT
ORDER BY 2 DESC;

\echo ''
\echo 'Distribution par année (pour décision de partitionnement) :'
\echo ''

-- Distribution temporelle
SELECT
    d.an as annee,
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    COUNT(DISTINCT v.id_vehicule) as nb_vehicules,
    COUNT(DISTINCT u.id_personne) as nb_usagers,
    pg_size_pretty(
        (COUNT(*) * pg_column_size(a.*))::BIGINT
    ) as taille_estimee
FROM ACCIDENT a
JOIN DATE_ACCIDENT d USING (num_acc)
LEFT JOIN VEHICULE v USING (num_acc)
LEFT JOIN USAGER u USING (num_acc)
WHERE d.an IS NOT NULL
GROUP BY d.an
ORDER BY d.an;

\echo ''
\echo 'Recommandation automatique :'
\echo ''

-- Recommandation de partitionnement
WITH stats AS (
    SELECT
        COUNT(DISTINCT an) as nb_annees,
        SUM(nb) as total_accidents
    FROM (
        SELECT an, COUNT(*) as nb
        FROM DATE_ACCIDENT
        WHERE an IS NOT NULL
        GROUP BY an
    ) t
)
SELECT
    CASE
        WHEN nb_annees >= 5 AND total_accidents > 500000 THEN
            '✅ PARTITIONNEMENT PAR ANNÉE FORTEMENT RECOMMANDÉ' ||
            E'\n   Raison : ' || nb_annees || ' années de données, ' ||
            total_accidents || ' accidents' ||
            E'\n   Gain attendu : 3-5x plus rapide sur requêtes temporelles' ||
            E'\n   Voir templates ci-dessous (section 7.1)'
        WHEN nb_annees >= 3 AND total_accidents > 200000 THEN
            '⚠️  PARTITIONNEMENT RECOMMANDÉ' ||
            E'\n   Raison : ' || nb_annees || ' années, ' ||
            total_accidents || ' accidents' ||
            E'\n   Gain attendu : 2-3x plus rapide'
        ELSE
            'ℹ️  Partitionnement optionnel' ||
            E'\n   Volumétrie : ' || total_accidents || ' accidents' ||
            E'\n   Indexation suffit pour l''instant'
    END as recommandation
FROM stats;

\echo ''
\echo ''

-- ============================================================================
-- 7.1 : TEMPLATES DE PARTITIONNEMENT PAR ANNÉE (2012-2019)
-- ============================================================================

\echo '──────────────────────────────────────────'
\echo '7.1 : Templates de partitionnement'
\echo '──────────────────────────────────────────'
\echo ''
\echo 'Les templates ci-dessous sont COMMENTÉS par défaut.'
\echo 'Décommenter et adapter selon vos besoins pour activer'
\echo 'le partitionnement par année.'
\echo ''

-- ============================================================================
-- TEMPLATE : Partitionnement de la table ACCIDENT
-- ============================================================================
/*
-- ──────────────────────────────────────────────────────────────────────────
-- ÉTAPE 1 : Créer la table ACCIDENT partitionnée
-- ──────────────────────────────────────────────────────────────────────────

-- IMPORTANT : Ajouter la colonne 'an' si elle n'existe pas déjà
-- ALTER TABLE ACCIDENT ADD COLUMN IF NOT EXISTS an INTEGER;
-- UPDATE ACCIDENT SET an = (SELECT an FROM DATE_ACCIDENT WHERE DATE_ACCIDENT.num_acc = ACCIDENT.num_acc);

CREATE TABLE ACCIDENT_PARTITIONED (
    num_acc BIGINT NOT NULL,
    an INTEGER NOT NULL,  -- Colonne de partitionnement (OBLIGATOIRE)
    lum INTEGER,
    atm INTEGER,
    col INTEGER,
    agg INTEGER,
    circ INTEGER,
    plan INTEGER,
    prof INTEGER,
    surf INTEGER,
    -- Ajoutez toutes les colonnes de votre table ACCIDENT
    PRIMARY KEY (num_acc, an)  -- PK doit inclure la clé de partition
) PARTITION BY RANGE (an);

-- ──────────────────────────────────────────────────────────────────────────
-- ÉTAPE 2 : Créer les partitions par année (2012-2019)
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE accident_2012 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2012) TO (2013);

CREATE TABLE accident_2013 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2013) TO (2014);

CREATE TABLE accident_2014 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2014) TO (2015);

CREATE TABLE accident_2015 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2015) TO (2016);

CREATE TABLE accident_2016 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2016) TO (2017);

CREATE TABLE accident_2017 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2017) TO (2018);

CREATE TABLE accident_2018 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2018) TO (2019);

CREATE TABLE accident_2019 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2019) TO (2020);

-- Extensions futures (2020-2024)
CREATE TABLE accident_2020 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2020) TO (2021);

CREATE TABLE accident_2021 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2021) TO (2022);

CREATE TABLE accident_2022 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2022) TO (2023);

CREATE TABLE accident_2023 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2023) TO (2024);

CREATE TABLE accident_2024 PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2024) TO (2025);

-- Partition par défaut (nouvelles années non prévues)
CREATE TABLE accident_future PARTITION OF ACCIDENT_PARTITIONED
    FOR VALUES FROM (2025) TO (MAXVALUE);

-- ──────────────────────────────────────────────────────────────────────────
-- ÉTAPE 3 : Migrer les données
-- ──────────────────────────────────────────────────────────────────────────

BEGIN;

-- Insérer les données
INSERT INTO ACCIDENT_PARTITIONED
SELECT * FROM ACCIDENT;

-- Vérification avant commit
DO $$
DECLARE
    nb_source INTEGER;
    nb_dest INTEGER;
BEGIN
    SELECT COUNT(*) INTO nb_source FROM ACCIDENT;
    SELECT COUNT(*) INTO nb_dest FROM ACCIDENT_PARTITIONED;

    IF nb_source != nb_dest THEN
        RAISE EXCEPTION 'ERREUR : % lignes en source vs % en destination', nb_source, nb_dest;
    ELSE
        RAISE NOTICE 'Validation OK : % lignes migrées', nb_dest;
    END IF;
END $$;

-- Si OK, valider
-- COMMIT;

-- Si problème, annuler
-- ROLLBACK;

-- ──────────────────────────────────────────────────────────────────────────
-- ÉTAPE 4 : Remplacer l'ancienne table (APRÈS VALIDATION)
-- ──────────────────────────────────────────────────────────────────────────

-- Sauvegarder l'ancienne table
-- ALTER TABLE ACCIDENT RENAME TO ACCIDENT_OLD;

-- Activer la nouvelle
-- ALTER TABLE ACCIDENT_PARTITIONED RENAME TO ACCIDENT;

-- Après validation complète, supprimer l'ancienne
-- DROP TABLE ACCIDENT_OLD;

-- ──────────────────────────────────────────────────────────────────────────
-- ÉTAPE 5 : Créer les index sur chaque partition
-- ──────────────────────────────────────────────────────────────────────────

-- Index automatiquement propagés aux partitions
CREATE INDEX idx_accident_lum_atm ON ACCIDENT_PARTITIONED(lum, atm);
CREATE INDEX idx_accident_conditions ON ACCIDENT_PARTITIONED(agg, circ, surf);
CREATE INDEX idx_accident_col ON ACCIDENT_PARTITIONED(col);

-- Analyse pour mettre à jour les statistiques
ANALYZE ACCIDENT_PARTITIONED;
*/

-- ============================================================================
-- TEMPLATE : Partitionnement de DATE_ACCIDENT (aligné avec ACCIDENT)
-- ============================================================================
/*
CREATE TABLE DATE_ACCIDENT_PARTITIONED (
    num_acc BIGINT NOT NULL,
    an INTEGER NOT NULL,
    mois INTEGER,
    jour INTEGER,
    hrmn INTEGER,
    datetime TIMESTAMP,
    PRIMARY KEY (num_acc, an)
) PARTITION BY RANGE (an);

-- Créer les mêmes partitions que pour ACCIDENT
CREATE TABLE date_accident_2012 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2012) TO (2013);
CREATE TABLE date_accident_2013 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2013) TO (2014);
CREATE TABLE date_accident_2014 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2014) TO (2015);
CREATE TABLE date_accident_2015 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2015) TO (2016);
CREATE TABLE date_accident_2016 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2016) TO (2017);
CREATE TABLE date_accident_2017 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2017) TO (2018);
CREATE TABLE date_accident_2018 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2018) TO (2019);
CREATE TABLE date_accident_2019 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2019) TO (2020);
CREATE TABLE date_accident_2020 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2020) TO (2021);
CREATE TABLE date_accident_2021 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2021) TO (2022);
CREATE TABLE date_accident_2022 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2022) TO (2023);
CREATE TABLE date_accident_2023 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2023) TO (2024);
CREATE TABLE date_accident_2024 PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2024) TO (2025);
CREATE TABLE date_accident_future PARTITION OF DATE_ACCIDENT_PARTITIONED FOR VALUES FROM (2025) TO (MAXVALUE);

-- Migration des données (même processus que pour ACCIDENT)
*/

\echo ''

-- ============================================================================
-- 7.2 : INDEX RECOMMANDÉS (SI PAS DE PARTITIONNEMENT)
-- ============================================================================

\echo '──────────────────────────────────────────'
\echo '7.2 : Index recommandés'
\echo '──────────────────────────────────────────'
\echo ''

\echo 'Index actuels sur les tables :'
\echo ''

-- Liste des index existants
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

\echo ''
\echo 'Index recommandés (décommenter pour créer) :'
\echo ''

/*
-- Index sur ACCIDENT
CREATE INDEX IF NOT EXISTS idx_accident_lum_atm ON ACCIDENT(lum, atm);
CREATE INDEX IF NOT EXISTS idx_accident_conditions ON ACCIDENT(agg, circ, surf);
CREATE INDEX IF NOT EXISTS idx_accident_col ON ACCIDENT(col);

-- Index sur USAGER
CREATE INDEX IF NOT EXISTS idx_usager_num_acc ON USAGER(num_acc);
CREATE INDEX IF NOT EXISTS idx_usager_grav ON USAGER(grav);
CREATE INDEX IF NOT EXISTS idx_usager_catu ON USAGER(catu);

-- Index sur VEHICULE
CREATE INDEX IF NOT EXISTS idx_vehicule_num_acc ON VEHICULE(num_acc);
CREATE INDEX IF NOT EXISTS idx_vehicule_catv ON VEHICULE(catv);

-- Index sur LIEUX
CREATE INDEX IF NOT EXISTS idx_lieux_num_acc ON LIEUX(num_acc);
CREATE INDEX IF NOT EXISTS idx_lieux_reg ON LIEUX(reg_code) WHERE reg_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lieux_dep ON LIEUX(dep_code) WHERE dep_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lieux_catr ON LIEUX(catr);

-- Index sur DATE_ACCIDENT
CREATE INDEX IF NOT EXISTS idx_date_num_acc ON DATE_ACCIDENT(num_acc);
CREATE INDEX IF NOT EXISTS idx_date_an_mois ON DATE_ACCIDENT(an, mois);
CREATE INDEX IF NOT EXISTS idx_date_an ON DATE_ACCIDENT(an) WHERE an IS NOT NULL;
*/

\echo ''

-- ============================================================================
-- 7.3 : TESTS DE PERFORMANCE (EXPLAIN ANALYZE)
-- ============================================================================

\echo '──────────────────────────────────────────'
\echo '7.3 : Tests de performance'
\echo '──────────────────────────────────────────'
\echo ''

-- Test 1 : Requête avec filtre temporel
\echo 'Test 1 : Requête avec filtre sur année (2017-2019)'
\echo ''

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT
    d.an,
    COUNT(DISTINCT a.num_acc) as nb_accidents,
    SUM(CASE WHEN u.grav = 2 THEN 1 ELSE 0 END) as nb_tues
FROM ACCIDENT a
INNER JOIN DATE_ACCIDENT d USING (num_acc)
INNER JOIN USAGER u USING (num_acc)
WHERE d.an BETWEEN 2017 AND 2019
GROUP BY d.an;

\echo ''
\echo ''

-- Test 2 : Requête avec vue matérialisée
\echo 'Test 2 : Même requête via vue matérialisée'
\echo ''

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT
    an,
    COUNT(*) as nb_accidents,
    SUM(nb_tues) as nb_tues
FROM analytics.accident_usagers_aggr
WHERE an BETWEEN 2017 AND 2019
GROUP BY an;

\echo ''
\echo '→ Comparer les temps d''exécution (Execution Time)'
\echo '→ Gain attendu : 5-10x avec vue matérialisée'
\echo ''
\echo ''

-- Test 3 : Requête complexe multi-tables
\echo 'Test 3 : Requête complexe (département + conditions + année)'
\echo ''

EXPLAIN (ANALYZE, BUFFERS, TIMING)
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
WHERE d.an = 2019
    AND l.dep_code IN ('75', '69', '13', '92', '93')
GROUP BY l.dep_code, a.lum, a.atm
ORDER BY nb_accidents DESC;

\echo ''
\echo ''

-- ============================================================================
-- 7.4 : STATISTIQUES D'UTILISATION DES INDEX
-- ============================================================================

\echo '──────────────────────────────────────────'
\echo '7.4 : Statistiques d''utilisation des index'
\echo '──────────────────────────────────────────'
\echo ''

SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as nb_utilisations,
    idx_tup_read as nb_tuples_lus,
    idx_tup_fetch as nb_tuples_recuperes,
    pg_size_pretty(pg_relation_size(indexrelid)) as taille_index,
    CASE
        WHEN idx_scan = 0 THEN '⚠️  Index non utilisé'
        WHEN idx_scan < 100 THEN 'Peu utilisé'
        WHEN idx_scan < 1000 THEN 'Utilisation modérée'
        ELSE '✅ Très utilisé'
    END as evaluation
FROM pg_stat_user_indexes
WHERE schemaname IN ('public', 'analytics')
    AND tablename IN ('ACCIDENT', 'VEHICULE', 'USAGER', 'LIEUX', 'DATE_ACCIDENT', 'accident_usagers_aggr')
ORDER BY idx_scan DESC, pg_relation_size(indexrelid) DESC;

\echo ''
\echo ''

-- ============================================================================
-- RÉSUMÉ ET RECOMMANDATIONS
-- ============================================================================

\echo '========================================'
\echo 'RÉSUMÉ DES RECOMMANDATIONS'
\echo '========================================'
\echo ''
\echo '1. PARTITIONNEMENT :'
\echo '   • Volumétrie : ~476k accidents, 8 années (2012-2019)'
\echo '   • Recommandation : FORTEMENT RECOMMANDÉ'
\echo '   • Action : Décommenter les templates section 7.1'
\echo '   • Gain attendu : 3-5x plus rapide sur requêtes temporelles'
\echo ''
\echo '2. INDEXATION :'
\echo '   • Vue matérialisée : Déjà indexée (section setup_dimensions.sql)'
\echo '   • Tables sources : Décommenter les index section 7.2 si besoin'
\echo ''
\echo '3. MAINTENANCE :'
\echo '   • Rafraîchir la vue après chaque chargement ETL :'
\echo '     psql -d accidents_db -f etl/sql/refresh_matviews.sql'
\echo ''
\echo '   • Analyser régulièrement les tables :'
\echo '     ANALYZE ACCIDENT;'
\echo '     ANALYZE analytics.accident_usagers_aggr;'
\echo ''
\echo '========================================'
\echo ''

-- ============================================================================
