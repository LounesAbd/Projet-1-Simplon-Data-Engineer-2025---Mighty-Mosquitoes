-- =========================================================================
-- RAFRAÎCHISSEMENT DE LA VUE MATÉRIALISÉE
-- =========================================================================
-- Objectif : Mettre à jour la vue matérialisée après chargement de nouvelles données
-- Usage : Exécuter après chaque chargement ETL
--         psql -d accidents_db -f etl/sql/refresh_matviews.sql
--
-- Mode CONCURRENT : Non bloquant (les lectures continuent pendant le refresh)
-- Durée estimée : 30-90 secondes sur ~476k accidents
-- =========================================================================

\echo '========================================='
\echo 'RAFRAÎCHISSEMENT VUE MATÉRIALISÉE'
\echo 'Mighty Mosquitoes - Accidents'
\echo '========================================='
\echo ''

-- -------------------------------------------------------------------------
-- Vérification existence
-- -------------------------------------------------------------------------

\echo '1/3 Vérification existence de la vue...'

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_matviews
        WHERE schemaname = 'analytics' AND matviewname = 'accident_usagers_aggr'
    ) THEN
        RAISE EXCEPTION '❌ Vue matérialisée introuvable. Exécuter d''abord : psql -f etl/sql/setup_dimensions.sql';
    END IF;

    RAISE NOTICE '  ✓ Vue matérialisée trouvée';
END $$;

\echo ''

-- -------------------------------------------------------------------------
-- Statistiques avant refresh
-- -------------------------------------------------------------------------

\echo '2/3 Statistiques avant rafraîchissement :'
\echo ''

SELECT
    'accident_usagers_aggr' as vue_materialisee,
    pg_size_pretty(pg_total_relation_size('analytics.accident_usagers_aggr')) as taille_totale,
    (SELECT COUNT(*) FROM analytics.accident_usagers_aggr) as nb_lignes,
    (SELECT SUM(nb_tues) FROM analytics.accident_usagers_aggr) as nb_tues_total,
    (SELECT COUNT(DISTINCT an) FROM analytics.accident_usagers_aggr WHERE an IS NOT NULL) as nb_annees_couvertes
\gx
\gx

\echo ''

-- -------------------------------------------------------------------------
-- Rafraîchissement
-- -------------------------------------------------------------------------

\echo '3/3 Rafraîchissement en cours...'
\echo '    Mode CONCURRENT (non bloquant - les lectures continuent)'
\echo '    ⏱️  Durée estimée : 30-90 secondes'
\echo ''

\timing on
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.accident_usagers_aggr;
\timing off

\echo ''
\echo '  ✅ Rafraîchissement terminé'
\echo ''

-- -------------------------------------------------------------------------
-- Statistiques après refresh
-- -------------------------------------------------------------------------

\echo 'Statistiques après rafraîchissement :'
\echo ''

SELECT
    'accident_usagers_aggr' as vue_materialisee,
    pg_size_pretty(pg_total_relation_size('analytics.accident_usagers_aggr')) as taille_totale,
    (SELECT COUNT(*) FROM analytics.accident_usagers_aggr) as nb_lignes,
    (SELECT SUM(nb_tues) FROM analytics.accident_usagers_aggr) as nb_tues_total,
    (SELECT COUNT(DISTINCT an) FROM analytics.accident_usagers_aggr WHERE an IS NOT NULL) as nb_annees_couvertes
\gx
\gx

\echo ''

-- -------------------------------------------------------------------------
-- Analyse pour mettre à jour les statistiques PostgreSQL
-- -------------------------------------------------------------------------

\echo 'Mise à jour des statistiques PostgreSQL...'

ANALYZE analytics.accident_usagers_aggr;

\echo '  ✅ Statistiques mises à jour'
\echo ''

-- -------------------------------------------------------------------------
-- Message final
-- -------------------------------------------------------------------------

\echo '========================================='
\echo '✅ RAFRAÎCHISSEMENT TERMINÉ !'
\echo '========================================='
\echo ''
\echo 'La vue matérialisée a été mise à jour avec succès.'
\echo ''
\echo 'Les requêtes analytiques peuvent maintenant utiliser'
\echo 'les données les plus récentes.'
\echo ''
\echo 'Pour exécuter les analyses :'
\echo '  psql -d accidents_db -f etl/sql/section1_kpi_zones.sql'
\echo '  psql -d accidents_db -f etl/sql/section2_kpi_conditions.sql'
\echo '  ...'
\echo ''
\echo '========================================='

-- =========================================================================
