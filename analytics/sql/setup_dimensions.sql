-- =========================================================================
-- SETUP DIMENSIONS & VUE AGRÉGÉE
-- =========================================================================
-- Objectif : centraliser la jointure ACCIDENT → LIEUX → USAGER → DATE_ACCIDENT
--            et normaliser les libellés métiers via des tables de dimensions.
-- Ce script est conçu pour être rejoué sans effet destructif.
--
-- Prérequis : Tables ACCIDENT, USAGER, LIEUX, DATE_ACCIDENT doivent exister
--             et contenir des données
--
-- Usage : psql -d accidents_db -f etl/sql/setup_dimensions.sql
-- =========================================================================

\echo '========================================='
\echo 'SETUP DIMENSIONS & VUE MATÉRIALISÉE'
\echo 'Mighty Mosquitoes - Accidents'
\echo '========================================='
\echo ''

-- -------------------------------------------------------------------------
-- VÉRIFICATION DES PRÉREQUIS
-- -------------------------------------------------------------------------

\echo '1/5 Vérification des prérequis...'

DO $$
DECLARE
    nb_accidents INTEGER;
BEGIN
    -- Vérifier existence des tables sources
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'accident') THEN
        RAISE EXCEPTION '❌ Table ACCIDENT introuvable. Exécuter d''abord le script ETL de création des tables.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'usager') THEN
        RAISE EXCEPTION '❌ Table USAGER introuvable. Exécuter d''abord le script ETL de création des tables.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'lieux') THEN
        RAISE EXCEPTION '❌ Table LIEUX introuvable. Exécuter d''abord le script ETL de création des tables.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'date_accident') THEN
        RAISE EXCEPTION '❌ Table DATE_ACCIDENT introuvable. Exécuter d''abord le script ETL de création des tables.';
    END IF;

    RAISE NOTICE '  ✓ Toutes les tables sources sont présentes';

    -- Vérifier qu'elles ne sont pas vides
    SELECT COUNT(*) INTO nb_accidents FROM ACCIDENT;

    IF nb_accidents = 0 THEN
        RAISE EXCEPTION '❌ Table ACCIDENT vide. Charger les données avant d''exécuter ce script.';
    END IF;

    RAISE NOTICE '  ✓ Tables sources non vides (% accidents détectés)', nb_accidents;
END $$;

\echo '  ✅ Prérequis validés'
\echo ''

-- -------------------------------------------------------------------------
-- CRÉATION DU SCHÉMA ANALYTIQUE
-- -------------------------------------------------------------------------

\echo '2/5 Création du schéma analytique...'

CREATE SCHEMA IF NOT EXISTS analytics;

\echo '  ✅ Schéma analytics créé (ou déjà existant)'
\echo ''

-- -------------------------------------------------------------------------
-- CRÉATION DES TABLES DE DIMENSIONS
-- -------------------------------------------------------------------------

\echo '3/5 Création des tables de dimensions...'

-- Table dim_agg (agglomération)
CREATE TABLE IF NOT EXISTS analytics.dim_agg (
    agg SMALLINT PRIMARY KEY,
    libelle TEXT NOT NULL
);

INSERT INTO analytics.dim_agg (agg, libelle) VALUES
    (1, 'Hors agglomération'),
    (2, 'En agglomération'),
    (3, 'Agglomération non précisée'),
    (4, 'Espace privé'),
    (0, 'Non renseigné')
ON CONFLICT (agg) DO UPDATE SET libelle = EXCLUDED.libelle;

\echo '  ✓ dim_agg créée (5 valeurs)'

-- Table dim_catr (catégorie de route)
CREATE TABLE IF NOT EXISTS analytics.dim_catr (
    catr SMALLINT PRIMARY KEY,
    libelle TEXT NOT NULL
);

INSERT INTO analytics.dim_catr (catr, libelle) VALUES
    (1, 'Autoroute'),
    (2, 'Route nationale'),
    (3, 'Route départementale'),
    (4, 'Voie communale'),
    (5, 'Hors réseau public'),
    (6, 'Parc de stationnement'),
    (7, 'Route de métropole urbaine'),
    (9, 'Autre'),
    (0, 'Non renseigné')
ON CONFLICT (catr) DO UPDATE SET libelle = EXCLUDED.libelle;

\echo '  ✓ dim_catr créée (9 valeurs)'

-- Table dim_circ (régime de circulation)
CREATE TABLE IF NOT EXISTS analytics.dim_circ (
    circ SMALLINT PRIMARY KEY,
    libelle TEXT NOT NULL
);

INSERT INTO analytics.dim_circ (circ, libelle) VALUES
    (1, 'À sens unique'),
    (2, 'Bidirectionnelle'),
    (3, 'À chaussées séparées'),
    (4, 'Voies d''affectation variable'),
    (0, 'Non renseigné')
ON CONFLICT (circ) DO UPDATE SET libelle = EXCLUDED.libelle;

\echo '  ✓ dim_circ créée (5 valeurs)'

-- Table dim_lum (luminosité)
CREATE TABLE IF NOT EXISTS analytics.dim_lum (
    lum SMALLINT PRIMARY KEY,
    libelle TEXT NOT NULL
);

INSERT INTO analytics.dim_lum (lum, libelle) VALUES
    (1, 'Plein jour'),
    (2, 'Crépuscule ou aube'),
    (3, 'Nuit sans éclairage public'),
    (4, 'Nuit avec éclairage public non allumé'),
    (5, 'Nuit avec éclairage public allumé'),
    (0, 'Non renseigné')
ON CONFLICT (lum) DO UPDATE SET libelle = EXCLUDED.libelle;

\echo '  ✓ dim_lum créée (6 valeurs)'

-- Table dim_atm (conditions atmosphériques)
CREATE TABLE IF NOT EXISTS analytics.dim_atm (
    atm SMALLINT PRIMARY KEY,
    libelle TEXT NOT NULL
);

INSERT INTO analytics.dim_atm (atm, libelle) VALUES
    (1, 'Normale'),
    (2, 'Pluie légère'),
    (3, 'Pluie forte'),
    (4, 'Neige ou grêle'),
    (5, 'Brouillard ou fumée'),
    (6, 'Vent fort ou tempête'),
    (7, 'Temps éblouissant'),
    (8, 'Temps couvert'),
    (9, 'Autre'),
    (0, 'Non renseigné')
ON CONFLICT (atm) DO UPDATE SET libelle = EXCLUDED.libelle;

\echo '  ✓ dim_atm créée (10 valeurs)'

-- Table dim_int (intersection)
CREATE TABLE IF NOT EXISTS analytics.dim_int (
    ints SMALLINT PRIMARY KEY,
    libelle TEXT NOT NULL
);

INSERT INTO analytics.dim_int (ints, libelle) VALUES
    (1, 'Hors intersection'),
    (2, 'Intersection en X'),
    (3, 'Intersection en T'),
    (4, 'Intersection en Y'),
    (5, 'Intersection à plus de 4 branches'),
    (6, 'Giratoire'),
    (7, 'Place'),
    (8, 'Passage à niveau'),
    (9, 'Autre intersection'),
    (0, 'Non renseigné')
ON CONFLICT (ints) DO UPDATE SET libelle = EXCLUDED.libelle;

\echo '  ✓ dim_int créée (10 valeurs)'

\echo '  ✅ Toutes les tables de dimensions créées'
\echo ''

-- -------------------------------------------------------------------------
-- CRÉATION DE LA VUE MATÉRIALISÉE
-- -------------------------------------------------------------------------

\echo '4/5 Création de la vue matérialisée accident_usagers_aggr...'
\echo '    (Cette opération peut prendre 30-90 secondes sur ~476k accidents)'

DO $plpgsql$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_matviews
        WHERE schemaname = 'analytics'
          AND matviewname = 'accident_usagers_aggr'
    ) THEN
        RAISE NOTICE '    Création en cours...';
        
        EXECUTE $mv$
            CREATE MATERIALIZED VIEW analytics.accident_usagers_aggr AS
            WITH u AS (
                SELECT
                    num_acc,
                    COUNT(*)                                  AS nb_usagers_total,
                    COUNT(*) FILTER (WHERE grav = 'Indemne')  AS nb_indemnes,
                    COUNT(*) FILTER (WHERE grav = 'Tué')      AS nb_tues,
                    COUNT(*) FILTER (WHERE grav = 'Blessé')   AS nb_blesses
                FROM USAGER
                GROUP BY num_acc
            ),
            v AS (
                SELECT
                    num_acc,
                    COUNT(DISTINCT vehicule_id) AS nb_vehicules_impliques
                FROM VEHICULE
                GROUP BY num_acc
            )
            SELECT
                a.num_acc,
                a.agg, a.circ, a.lum, a.atm, a.col AS code_collision,
                l.reg_code, l.reg_name, l.dep_code, l.dep_name,
                l.com_code, l.com_name, l.catr, a.surf, l.vosp, a.prof, a.plan,
                d.an, d.mois, d.jour, d.hrmn,

                COALESCE(u.nb_usagers_total, 0)       AS nb_usagers_total,
                COALESCE(u.nb_indemnes, 0)            AS nb_indemnes,
                COALESCE(u.nb_tues, 0)                AS nb_tues,
                COALESCE(u.nb_blesses, 0)             AS nb_blesses,
                COALESCE(v.nb_vehicules_impliques, 0) AS nb_vehicules_impliques
            FROM ACCIDENT a
            INNER JOIN LIEUX l USING (num_acc)
            INNER JOIN DATE_ACCIDENT d USING (num_acc)
            LEFT  JOIN u USING (num_acc)
            LEFT  JOIN v USING (num_acc)
            GROUP BY
                a.num_acc, a.agg, a.circ, a.lum, a.atm, a.col,
                l.reg_code, l.reg_name, l.dep_code, l.dep_name,
                l.com_code, l.com_name, l.catr, a.surf, l.vosp, a.prof, a.plan,
                d.an, d.mois, d.jour, d.hrmn,
                u.nb_usagers_total, u.nb_indemnes, u.nb_tues, u.nb_blesses,
                v.nb_vehicules_impliques;
        $mv$;

        RAISE NOTICE '    ✓ Vue matérialisée créée avec succès';
    ELSE
        RAISE NOTICE '    ⚠️  Vue matérialisée déjà existante. Utiliser refresh_matviews.sql pour la mettre à jour';
    END IF;
END
$plpgsql$ LANGUAGE plpgsql;



\echo '  ✅ Vue matérialisée prête'
\echo ''

-- -------------------------------------------------------------------------
-- VALIDATION POST-CRÉATION
-- -------------------------------------------------------------------------

\echo 'Validation de la vue matérialisée...'

DO $$
DECLARE
    nb_accidents_source INTEGER;
    nb_accidents_vue INTEGER;
    nb_tues_source INTEGER;
    nb_tues_vue INTEGER;
BEGIN
    SELECT COUNT(*) INTO nb_accidents_source FROM ACCIDENT;
    SELECT COUNT(*) INTO nb_accidents_vue FROM analytics.accident_usagers_aggr;

    SELECT SUM(CASE WHEN grav = 'Tué' THEN 1 ELSE 0 END) INTO nb_tues_source FROM USAGER;
    SELECT SUM(nb_tues) INTO nb_tues_vue FROM analytics.accident_usagers_aggr;

    IF nb_accidents_source != nb_accidents_vue THEN
        RAISE WARNING '⚠️  Nombre de lignes différent : % (source) vs % (vue)',
                      nb_accidents_source, nb_accidents_vue;
    ELSE
        RAISE NOTICE '  ✓ Validation OK : % accidents dans la vue', nb_accidents_vue;
    END IF;

    IF nb_tues_source != nb_tues_vue THEN
        RAISE WARNING '⚠️  Nombre de tués différent : % (source) vs % (vue)',
                      nb_tues_source, nb_tues_vue;
    ELSE
        RAISE NOTICE '  ✓ Validation OK : % tués comptabilisés', nb_tues_vue;
    END IF;
END $$;

\echo ''

-- -------------------------------------------------------------------------
-- CRÉATION DES INDEX
-- -------------------------------------------------------------------------

\echo '5/5 Création des index sur la vue matérialisée...'

CREATE INDEX IF NOT EXISTS idx_accident_usagers_aggr_reg ON analytics.accident_usagers_aggr (reg_code);
\echo '  ✓ Index sur reg_code'

CREATE INDEX IF NOT EXISTS idx_accident_usagers_aggr_dep ON analytics.accident_usagers_aggr (dep_code);
\echo '  ✓ Index sur dep_code'

CREATE INDEX IF NOT EXISTS idx_accident_usagers_aggr_com ON analytics.accident_usagers_aggr (com_code);
\echo '  ✓ Index sur com_code'

CREATE INDEX IF NOT EXISTS idx_accident_usagers_aggr_agg ON analytics.accident_usagers_aggr (agg);
\echo '  ✓ Index sur agg (agglomération)'

CREATE INDEX IF NOT EXISTS idx_accident_usagers_aggr_catr ON analytics.accident_usagers_aggr (catr);
\echo '  ✓ Index sur catr (catégorie route)'

CREATE INDEX IF NOT EXISTS idx_accident_usagers_aggr_an_mois ON analytics.accident_usagers_aggr (an, mois);
\echo '  ✓ Index composite sur (an, mois)'

CREATE INDEX IF NOT EXISTS idx_accident_usagers_aggr_lum_atm ON analytics.accident_usagers_aggr (lum, atm);
\echo '  ✓ Index composite sur (lum, atm)'

\echo '  ✅ Tous les index créés'
\echo ''

-- =========================================================================
-- MESSAGE FINAL
-- =========================================================================

\echo '========================================='
\echo '✅ SETUP TERMINÉ AVEC SUCCÈS !'
\echo '========================================='
\echo ''
\echo 'Schéma analytics créé avec :'
\echo '  • 6 tables de dimensions (dim_agg, dim_catr, dim_circ, dim_lum, dim_atm, dim_int)'
\echo '  • 1 vue matérialisée (accident_usagers_aggr)'
\echo '  • 7 index pour optimiser les requêtes'
\echo ''
\echo 'Prochaines étapes :'
\echo '  1. Tester les requêtes analytiques :'
\echo '     psql -d accidents_db -f etl/sql/section1_kpi_zones.sql'
\echo 'psql -U postgres -h localhost -d db_accm -f analytics/sql/section1_kpi_zones.sql
\echo '  2. Valider la refactorisation :'
\echo '     psql -d accidents_db -f etl/sql/tests_validation.sql'
\echo ''
\echo '  3. Rafraîchir la vue après chargement de nouvelles données :'
\echo '     psql -d accidents_db -f etl/sql/refresh_matviews.sql'
\echo ''
\echo '========================================='

-- =========================================================================
