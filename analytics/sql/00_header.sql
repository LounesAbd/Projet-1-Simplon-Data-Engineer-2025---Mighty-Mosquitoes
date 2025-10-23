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
