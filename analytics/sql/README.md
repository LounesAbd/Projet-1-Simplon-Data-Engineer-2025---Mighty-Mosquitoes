# Découpage SQL Mighty Mosquitoes

Ce dossier regroupe les blocs SQL initialement présents dans `etl/requet_sql.sql`. Le fichier principal est désormais un orchestrateur basé sur `\ir` qui exécute chaque section.

## Fichiers
- `00_header.sql` : connexion à la base et rappel du périmètre.
- `setup_dimensions.sql` : création des tables de dimensions et de la vue agrégée `analytics.accident_usagers_aggr`.
- `section1_kpi_zones.sql` : KPI sur les zones à risque (régions, communes, type de route...).
- `section2_kpi_conditions.sql` : KPI liés aux conditions de survenue (météo, luminosité, profils usagers).
- `section3_kpi_tendances.sql` : séries temporelles et saisonnalité des accidents.
- `section4_conditions_risque.sql` : analyses statistiques (scores de risque, corrélations).
- `section5_flux_graves.sql` : comparaison zones fréquentées / accidents graves.
- `section6_anomalies_temporelles.sql` : détection d'anomalies hebdomadaires et contextuelles.
- `section7_optimisation.sql` : scripts d'indexation, partitionnement, plans d'exécution.
- `bonus_vues_utiles.sql` : statistiques de synthèse et vues rapides.
- `legacy_section1_kpi_zones.sql` : sauvegarde temporaire des requêtes brutes (Section 1) pour validation.
- `legacy_section2_kpi_conditions.sql` : sauvegarde temporaire des requêtes brutes (Section 2) pour validation.
- `legacy_section3_kpi_tendances.sql` : sauvegarde temporaire des requêtes brutes (Section 3) pour validation.
- `legacy_section4_conditions_risque.sql` : sauvegarde temporaire des requêtes brutes (Section 4) pour validation.
- `legacy_section5_flux_graves.sql` : sauvegarde temporaire des requêtes brutes (Section 5) pour validation.
- `legacy_section6_anomalies_temporelles.sql` : sauvegarde temporaire des requêtes brutes (Section 6) pour validation.

## Étapes de refactorisation prévues
1. Valider le script `setup_dimensions.sql` dès que la base ETL est opérationnelle (création du schéma, dimensions, vue matérialisée, index).
2. Comparer et valider les nouvelles sections agrégées (1 à 6) face aux scripts legacy avant retrait définitif.
3. Mettre à jour `section7_optimisation.sql` pour recommander des index spécifiques à la vue/dimensions créées et ajouter un bloc de `REFRESH` ciblé.
4. Ajouter des tests de cohérence (ex. comparaisons d'effectifs) dès que la base ETL sera disponible.

## Bonnes pratiques
- Exécuter `psql -f etl/requet_sql.sql` depuis la racine du projet pour lancer l'ensemble.
- Utiliser les sections individuelles via `\ir sql/<fichier>.sql` pour travailler un périmètre spécifique.
- Tenir ce README synchronisé avec la structure des fichiers et les travaux en cours.
