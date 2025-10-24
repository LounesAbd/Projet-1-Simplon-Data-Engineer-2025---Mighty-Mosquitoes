# Requêtes SQL Analytiques - Mighty Mosquitoes

## Table des Matières

- [Vue d'ensemble](#vue-densemble)
- [Prérequis et Dépendances](#prérequis-et-dépendances)
- [Architecture des Fichiers](#architecture-des-fichiers)
- [Guide de Démarrage Rapide](#guide-de-démarrage-rapide)
- [Description Détaillée des Sections](#description-détaillée-des-sections)
  - [Section 1 : Zones à Risque](#section-1--zones-à-risque-14-requêtes)
  - [Section 2 : Conditions de Survenue](#section-2--conditions-de-survenue-12-requêtes)
  - [Section 3 : Tendances Temporelles](#section-3--tendances-temporelles-8-requêtes)
  - [Section 4 : Conditions à Risque](#section-4--conditions-à-risque-3-requêtes)
  - [Section 5 : Zones Fréquentées vs Accidents Graves](#section-5--zones-fréquentées-vs-accidents-graves-3-requêtes)
  - [Section 6 : Anomalies Temporelles](#section-6--anomalies-temporelles-2-requêtes)
  - [Section 7 : Optimisation](#section-7--optimisation-non-implémenté)
  - [Bonus : Analyses Avancées](#bonus--analyses-avancées-3-requêtes)
- [Tables de Dimensions](#tables-de-dimensions)
- [Vue Matérialisée](#vue-matérialisée)
- [Utilisation avec Python](#utilisation-avec-python)
- [Maintenance et Rafraîchissement](#maintenance-et-rafraîchissement)
- [Bonnes Pratiques](#bonnes-pratiques)

---

## Vue d'ensemble

Ce dossier contient l'ensemble des **requêtes SQL analytiques** du projet Mighty Mosquitoes, organisées par thématique. Les requêtes sont conçues pour exploiter une **vue matérialisée optimisée** (`analytics.accident_usagers_aggr`) et des **tables de dimensions** qui normalisent les libellés métiers.

### Objectifs
- Fournir des **KPI opérationnels** pour identifier les zones et conditions à risque
- Détecter les **tendances temporelles** et **anomalies** dans les données d'accidents
- Effectuer des **analyses statistiques avancées** (z-score, corrélations, scores de risque)
- Optimiser les performances grâce à des **vues pré-calculées** et des **index stratégiques**

### Statistiques
- **42 requêtes analytiques** réparties en 6 sections + bonus
- **6 tables de dimensions** pour la normalisation
- **1 vue matérialisée** centralisant les jointures principales
- **7 index optimisés** pour des performances

---

## Prérequis et Dépendances

### Base de Données
- PostgreSQL 12+ (requis pour les vues matérialisées et fonctions window avancées)
- Base de données `db_accm` avec les tables sources :
  - `ACCIDENT` : données principales des accidents
  - `LIEUX` : localisation géographique
  - `USAGER` : personnes impliquées
  - `VEHICULE` : véhicules impliqués
  - `DATE_ACCIDENT` : informations temporelles

### Ordre d'Exécution
1. **Création des tables sources** (via ETL) - voir `etl/README.md`
2. **Setup dimensions** : [setup_dimensions.sql](setup_dimensions.sql) (OBLIGATOIRE)
3. **Requêtes analytiques** : sections 1-6 + bonus

### Droits Nécessaires
- `CREATE SCHEMA` sur la base
- `CREATE TABLE`, `CREATE INDEX` sur le schéma `analytics`
- `CREATE MATERIALIZED VIEW` et `REFRESH MATERIALIZED VIEW`
- `SELECT` sur les tables sources (`public.ACCIDENT`, etc.)

---

## Architecture des Fichiers

### Fichiers de Setup

| Fichier | Description | Dépendances | Temps d'exécution |
|---------|-------------|-------------|-------------------|
| [00_header.sql](00_header.sql) | Header de connexion et rappel du périmètre | - | < 1s |
| [setup_dimensions.sql](setup_dimensions.sql) | Création schéma analytics, dimensions, vue matérialisée, index | Tables sources | 30-90s |
| [refresh_matviews.sql](refresh_matviews.sql) | Rafraîchissement de la vue matérialisée | setup_dimensions.sql | 30-90s |

### Fichiers de Requêtes Analytiques

| Fichier | Requêtes | Description | Vue utilisée |
|---------|----------|-------------|--------------|
| [section1_kpi_zones.sql](section1_kpi_zones.sql) | 14 | Zones à risque (régions, départements, communes, routes) | accident_usagers_aggr |
| [section2_kpi_conditions.sql](section2_kpi_conditions.sql) | 12 | Conditions de survenue (météo, luminosité, usagers) | accident_usagers_aggr + USAGER + VEHICULE |
| [section3_kpi_tendances.sql](section3_kpi_tendances.sql) | 8 | Tendances temporelles (années, mois, jours, heures) | accident_usagers_aggr |
| [section4_conditions_risque.sql](section4_conditions_risque.sql) | 3 | Analyses statistiques (z-score, corrélations) | accident_usagers_aggr |
| [section5_flux_graves.sql](section5_flux_graves.sql) | 3 | Comparaison volume vs gravité | accident_usagers_aggr |
| [section6_anomalies_temporelles.sql](section6_anomalies_temporelles.sql) | 2 | Détection d'anomalies hebdomadaires | accident_usagers_aggr |
| [section7_optimisation.sql](section7_optimisation.sql) | - | Scripts d'optimisation (partitionnement, plans) | - |
| [bonus_analyses_avancees.sql](bonus_analyses_avancees.sql) | 3 | "Cocktail mortel", "Effet week-end saisonnier" | ACCIDENT + LIEUX + DATE_ACCIDENT + USAGER |
| [bonus_vues_utiles.sql](bonus_vues_utiles.sql) | - | Vues de synthèse rapide | Tables sources |

---

## Guide de Démarrage Rapide

### 1. Setup Initial (première utilisation uniquement)

```bash
# Créer le schéma analytics + dimensions + vue matérialisée + index
psql -U postgres -h localhost -d db_accm -f analytics/sql/setup_dimensions.sql
```

**Durée** : 30-90 secondes pour ~476k accidents

**Ce script va :**
- ✅ Vérifier les prérequis (tables sources)
- ✅ Créer le schéma `analytics`
- ✅ Créer 6 tables de dimensions
- ✅ Créer la vue matérialisée `accident_usagers_aggr`
- ✅ Créer 7 index optimisés
- ✅ Valider la cohérence des données

### 2. Exécuter une Section Spécifique

```bash
# Section 1 : Zones à risque
psql -U postgres -h localhost -d db_accm -f analytics/sql/section1_kpi_zones.sql

# Section 2 : Conditions de survenue
psql -U postgres -h localhost -d db_accm -f analytics/sql/section2_kpi_conditions.sql

# Section 3 : Tendances temporelles
psql -U postgres -h localhost -d db_accm -f analytics/sql/section3_kpi_tendances.sql

# Analyses avancées bonus
psql -U postgres -h localhost -d db_accm -f analytics/sql/bonus_analyses_avancees.sql
```

### 3. Rafraîchir la Vue Matérialisée (après chargement de nouvelles données)

```bash
psql -U postgres -h localhost -d db_accm -f analytics/sql/refresh_matviews.sql
```

---

## Description Détaillée des Sections

### Section 1 : Zones à Risque (14 requêtes)

**Objectif** : Identifier les zones géographiques et types de routes présentant le plus grand nombre d'accidents et/ou la plus forte gravité.

**Fichier** : [section1_kpi_zones.sql](section1_kpi_zones.sql)

#### KPI Prioritaires

| ID | Titre | Description | Métriques Clés |
|----|-------|-------------|----------------|
| 1.1 | Top 10 régions | Régions les plus accidentogènes | `nb_accidents`, `taux_mortalite_pct`, `rang` |
| 1.2 | Top 10 départements | Départements par volume d'accidents | `nb_tues`, `pct_accidents_mortels` |
| 1.3 | Agglo vs Non-agglo | Répartition accidents en/hors agglomération | `pct_accidents`, `taux_mortalite_pct` |
| 1.4 | Types de routes | Autoroute, nationale, départementale, communale | `nb_accidents`, `taux_mortalite_pct` |

#### KPI Secondaires

| ID | Titre | Description |
|----|-------|-------------|
| 1.5.1 | Régime de circulation | À sens unique, bidirectionnelle, chaussées séparées |
| 1.5.2 | Voies réservées | Piste cyclable, couloir bus, voie réservée |
| 1.6.1 | État de la surface | Normale, mouillée, flaques, inondée, enneigée, verglacée |
| 1.6.2 | Profil de la route | Plat, pente, sommet de côte, bas de côte |
| 1.6.3 | Tracé en plan | Ligne droite, courbe à gauche/droite, en S |
| 1.7.1 | Intersections | Hors intersection, X, T, Y, giratoire, passage à niveau |
| 1.8 | Top 20 communes | Communes les plus accidentogènes |
| 1.9 | Analyse par région (détaillée) | Statistiques complètes par région |
| 1.10 | Densité accidents/gravité | Croisement volume/taux de mortalité par département |
| 1.11 | Points noirs | Départements à faible volume mais forte gravité |

**Exemple de Requête** :
```sql
-- 1.1 : Top 10 régions les plus accidentogènes
WITH stats AS (
    SELECT
        reg_code,
        reg_name,
        COUNT(*) AS nb_accidents,
        SUM(nb_tues) AS nb_tues,
        SUM(nb_usagers_total) AS nb_personnes_impliquees
    FROM analytics.accident_usagers_aggr
    WHERE reg_code IS NOT NULL
    GROUP BY reg_code, reg_name
)
SELECT
    reg_name,
    nb_accidents,
    nb_tues,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct,
    DENSE_RANK() OVER (ORDER BY nb_accidents DESC) AS rang
FROM stats
ORDER BY nb_accidents DESC
LIMIT 10;
```

---

### Section 2 : Conditions de Survenue (12 requêtes)

**Objectif** : Analyser l'impact des conditions météorologiques, de luminosité et des profils usagers sur la survenue et la gravité des accidents.

**Fichier** : [section2_kpi_conditions.sql](section2_kpi_conditions.sql)

#### KPI Prioritaires

| ID | Titre | Description | Métriques Clés |
|----|-------|-------------|----------------|
| 2.1 | Conditions météo | Normale, pluie, neige, brouillard, vent, temps éblouissant | `nb_accidents`, `taux_mortalite_pct` |
| 2.2 | État de la voirie | Surface normale, mouillée, enneigée, boueuse | `nb_accidents`, `rang` |
| 2.3 | Luminosité | Jour, crépuscule, nuit (avec/sans éclairage) | `pct_accidents`, `taux_mortalite_pct` |
| 2.4 | Type de collision | Frontale, arrière, latérale, chaîne, piéton, fixe | `nb_accidents`, `nb_tues` |
| 2.5 | Type de véhicule | Vélo, moto, VL, VU, PL, TC, tracteur | `nb_vehicules`, `pct_accidents` |
| 2.6 | Type d'usagers | Conducteur, passager, piéton | `nb_personnes`, `taux_mortalite_pct` |

#### KPI Secondaires

| ID | Titre | Description |
|----|-------|-------------|
| 2.7 | Pyramide des âges | Distribution par tranche d'âge et gravité |
| 2.8 | Sexe des usagers | Répartition hommes/femmes victimes |
| 2.9 | Moto par cylindrée | Léger, moyen, lourd |
| 2.10 | Croisement lumière × météo | Combinaisons dangereuses |
| 2.11 | Obstacles fixes | Arbre, poteau, glissière, parapet, fossé |
| 2.12 | Manœuvres avant accident | Droite, gauche, U-turn, marche arrière, stationnement |

**Exemple de Requête** :
```sql
-- 2.3 : Conditions de luminosité les plus accidentogènes
WITH stats AS (
    SELECT
        aua.lum AS code_lumiere,
        dim.libelle AS libelle_lumiere,
        COUNT(*) AS nb_accidents,
        SUM(aua.nb_tues) AS nb_tues,
        SUM(aua.nb_usagers_total) AS nb_personnes_impliquees
    FROM analytics.accident_usagers_aggr aua
    LEFT JOIN analytics.dim_lum dim ON aua.lum = dim.lum
    GROUP BY aua.lum, dim.libelle
)
SELECT
    libelle_lumiere,
    nb_accidents,
    nb_tues,
    ROUND(100.0 * nb_accidents / SUM(nb_accidents) OVER (), 2) AS pct_accidents,
    ROUND(100.0 * nb_tues / NULLIF(nb_personnes_impliquees, 0), 2) AS taux_mortalite_pct
FROM stats
ORDER BY nb_accidents DESC;
```

---

### Section 3 : Tendances Temporelles (8 requêtes)

**Objectif** : Identifier les patterns temporels (saisonnalité, jours/heures à risque) et suivre l'évolution des accidents dans le temps.

**Fichier** : [section3_kpi_tendances.sql](section3_kpi_tendances.sql)

#### KPI Prioritaires

| ID | Titre | Description | Métriques Clés |
|----|-------|-------------|----------------|
| 3.1 | Évolution annuelle | Accidents par année avec évolution % | `nb_accidents`, `pct_evolution`, `taux_mortalite_pct` |
| 3.2 | Saisonnalité mensuelle | Accidents par mois (toutes années confondues) | `nb_accidents`, `moyenne_accidents_par_an` |
| 3.3 | Répartition horaire | Accidents par heure de la journée | `nb_accidents`, `tranche_horaire` |
| 3.4 | Jour de la semaine | Lundi-Dimanche + distinction semaine/week-end | `nb_accidents`, `moyenne_par_occurrence` |

#### KPI Secondaires

| ID | Titre | Description |
|----|-------|-------------|
| 3.5 | Heures de pointe | Identification des heures critiques |
| 3.6 | Heatmap mois × jour | Croisement mois/jour de la semaine |
| 3.7 | Tendance multi-années | Évolution détaillée par an et mois |
| 3.8 | Pics saisonniers | Identification des périodes à risque (vacances, fêtes) |

**Exemple de Requête** :
```sql
-- 3.2 : Saisonnalité mensuelle
WITH stats AS (
    SELECT
        mois,
        COUNT(*) AS nb_accidents,
        COUNT(DISTINCT an) AS nb_annees_observees,
        SUM(nb_tues) AS nb_tues
    FROM analytics.accident_usagers_aggr
    WHERE mois IS NOT NULL
    GROUP BY mois
)
SELECT
    CASE mois
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
    END AS nom_mois,
    nb_accidents,
    nb_tues,
    ROUND(nb_accidents::NUMERIC / nb_annees_observees, 2) AS moyenne_accidents_par_an,
    ROUND(100.0 * nb_accidents / SUM(nb_accidents) OVER (), 2) AS pct_accidents
FROM stats
ORDER BY mois;
```

---

### Section 4 : Conditions à Risque (3 requêtes)

**Objectif** : Analyses statistiques avancées pour identifier les combinaisons de facteurs à haut risque.

**Fichier** : [section4_conditions_risque.sql](section4_conditions_risque.sql)

#### Requêtes Avancées

| ID | Titre | Description | Métriques Clés |
|----|-------|-------------|----------------|
| 4.1 | Combinaisons dangereuses (z-score) | Météo × Luminosité × Type de route | `z_score`, `gravite_moyenne`, `niveau_risque` |
| 4.2 | Corrélation gravité/conditions | Coefficient de Pearson entre conditions | `correlation`, `significance` |
| 4.3 | Matrice de risque | Heatmap croisée conditions atmosphériques/luminosité | `nb_accidents`, `taux_mortalite` |

**Méthodologie** :
- **Score de gravité** : `100 * nb_tués + 7 * nb_blessés`
- **Z-score** : `(gravité_combinaison - gravité_moyenne_nationale) / écart_type`
- **Seuils de risque** :
  - z-score > 2 : **RISQUE TRÈS ÉLEVÉ**
  - z-score > 1 : **RISQUE ÉLEVÉ**
  - z-score > 0 : **RISQUE MODÉRÉ**
  - z-score ≤ 0 : **RISQUE FAIBLE**

---

### Section 5 : Zones Fréquentées vs Accidents Graves (3 requêtes)

**Objectif** : Identifier les zones à fort trafic mais faible gravité (prévention efficace) vs zones à faible trafic mais forte gravité (points noirs).

**Fichier** : [section5_flux_graves.sql](section5_flux_graves.sql)

#### Requêtes Avancées

| ID | Titre | Description | Profils Identifiés |
|----|-------|-------------|-------------------|
| 5.1 | Analyse départementale (volume vs gravité) | Classement croisé volume/gravité | Dense ET dangereux, Dense mais PEU dangereux, Peu dense mais TRÈS dangereux |
| 5.2 | Corrélation volume/gravité | Coefficient de Pearson | FAIBLE, MODÉRÉE, FORTE |
| 5.3 | Cartographie du risque | Classification par quadrant | 4 profils de zones |

**Interprétation** :
- **Zone dense ET dangereuse** : intervention prioritaire (renforcement sécurité)
- **Zone dense mais PEU dangereuse** : bonnes pratiques à étudier
- **Zone peu dense mais TRÈS dangereuse** : points noirs à traiter
- **Zone moyenne** : surveillance standard

---

### Section 6 : Anomalies Temporelles (2 requêtes)

**Objectif** : Détecter les pics et creux inhabituels dans les données d'accidents pour identifier des événements exceptionnels.

**Fichier** : [section6_anomalies_temporelles.sql](section6_anomalies_temporelles.sql)

#### Requêtes Avancées

| ID | Titre | Description | Métriques Clés |
|----|-------|-------------|----------------|
| 6.1 | Analyse hebdomadaire (z-score) | Détection d'anomalies semaine par semaine | `z_score_volume`, `type_anomalie`, `tendance` |
| 6.2 | Pics saisonniers | Mois × week-end avec suraccidentalité | `indice_weekend`, `niveau_alerte` |

**Méthodologie** :
- **Anomalie EXTRÊME** : |z-score| > 3σ (< 0,3% de probabilité)
- **Anomalie FORTE** : |z-score| > 2σ (< 5% de probabilité)
- **Anomalie MODÉRÉE** : |z-score| > 1,5σ (< 13% de probabilité)
- **NORMAL** : |z-score| ≤ 1,5σ

---

### Section 7 : Optimisation (non implémenté)

**Objectif** : Scripts d'optimisation avancée (partitionnement, plans d'exécution).

**Fichier** : [section7_optimisation.sql](section7_optimisation.sql)

**Statut** : Non implémenté faute de temps suite à la réception tardive de la base de données.

**Contenu prévu** :
- Partitionnement temporel de `accident_usagers_aggr` (par année)
- Index covering supplémentaires
- Analyse des plans d'exécution (`EXPLAIN ANALYZE`)
- Recommandations d'optimisation PostgreSQL
- Scripts de vacuum et maintenance

---

### Bonus : Analyses Avancées (3 requêtes)

**Objectif** : Requêtes innovantes et complexes pour des insights approfondis.

**Fichier** : [bonus_analyses_avancees.sql](bonus_analyses_avancees.sql)

#### Requêtes Innovantes

| Titre | Description | Complexité | Temps d'exécution |
|-------|-------------|------------|-------------------|
| **"Cocktail mortel"** | Combinaisons multi-facteurs (atmosphère × luminosité × route × heure × agglo) avec score de létalité et z-score | Très élevée | 3-5 secondes |
| **"Effet week-end saisonnier"** | Croisement jour × mois × heure pour identifier les périodes critiques (ex: vendredis soirs d'été) | Très élevée | 2-4 secondes |
| **Vue d'ensemble rapide** | KPI de synthèse pour tableau de bord (période couverte, totaux, taux globaux) | Faible | < 1 seconde |

**Exemple de Requête (Cocktail Mortel)** :
```sql
WITH combinaisons AS (
    SELECT
        a.atm, a.lum, l.catr, a.agg,
        CASE
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 0 AND 5 THEN 'Nuit (00h-06h)'
            WHEN EXTRACT(HOUR FROM d.hrmn) BETWEEN 18 AND 21 THEN 'Soirée (18h-22h)'
            -- ...
        END AS tranche_horaire,
        COUNT(DISTINCT a.num_acc) AS nb_accidents,
        SUM(CASE WHEN u.grav = 'Tué' THEN 1 ELSE 0 END) AS nb_tues,
        (100.0 * SUM(CASE WHEN u.grav = 'Tué' THEN 1 ELSE 0 END) +
         7.0 * SUM(CASE WHEN u.grav = 'Blessés' THEN 1 ELSE 0 END)) /
         COUNT(*) AS score_gravite
    FROM ACCIDENT a
    INNER JOIN LIEUX l USING (num_acc)
    INNER JOIN DATE_ACCIDENT d USING (num_acc)
    INNER JOIN USAGER u USING (num_acc)
    GROUP BY a.atm, a.lum, l.catr, a.agg, tranche_horaire
    HAVING COUNT(DISTINCT a.num_acc) >= 50
),
avec_zscore AS (
    SELECT *,
        ROUND((score_gravite - AVG(score_gravite) OVER ()) /
              STDDEV(score_gravite) OVER (), 2) AS z_score_gravite,
        CASE
            WHEN (score_gravite - AVG(score_gravite) OVER ()) / STDDEV(score_gravite) OVER () > 2.5
            THEN '🔴 EXTRÊMEMENT DANGEREUX'
            WHEN (score_gravite - AVG(score_gravite) OVER ()) / STDDEV(score_gravite) OVER () > 1.5
            THEN '🟠 TRÈS DANGEREUX'
            ELSE '🟡 DANGEREUX'
        END AS niveau_risque
    FROM combinaisons
)
SELECT * FROM avec_zscore
ORDER BY score_gravite DESC
LIMIT 30;
```

---

## Tables de Dimensions

Les tables de dimensions normalisent les libellés métiers pour faciliter les jointures et améliorer la lisibilité.

### Schéma : `analytics`

| Table | Champ Clé | Nb Valeurs | Description |
|-------|-----------|------------|-------------|
| `dim_agg` | `agg` | 5 | Type d'agglomération |
| `dim_catr` | `catr` | 9 | Catégorie de route |
| `dim_circ` | `circ` | 5 | Régime de circulation |
| `dim_lum` | `lum` | 6 | Conditions de luminosité |
| `dim_atm` | `atm` | 10 | Conditions atmosphériques |
| `dim_int` | `ints` | 10 | Type d'intersection |

### Détails des Dimensions

#### dim_agg (Agglomération)
```sql
1 → Hors agglomération
2 → En agglomération
3 → Agglomération non précisée
4 → Espace privé
0 → Non renseigné
```

#### dim_catr (Catégorie de Route)
```sql
1 → Autoroute
2 → Route nationale
3 → Route départementale
4 → Voie communale
5 → Hors réseau public
6 → Parc de stationnement
7 → Route de métropole urbaine
9 → Autre
0 → Non renseigné
```

#### dim_lum (Luminosité)
```sql
1 → Plein jour
2 → Crépuscule ou aube
3 → Nuit sans éclairage public
4 → Nuit avec éclairage public non allumé
5 → Nuit avec éclairage public allumé
0 → Non renseigné
```

#### dim_atm (Conditions Atmosphériques)
```sql
1 → Normale
2 → Pluie légère
3 → Pluie forte
4 → Neige ou grêle
5 → Brouillard ou fumée
6 → Vent fort ou tempête
7 → Temps éblouissant
8 → Temps couvert
9 → Autre
0 → Non renseigné
```

### Utilisation dans les Requêtes

```sql
-- Exemple : Joindre la dimension luminosité
SELECT
    dim_lum.libelle AS condition_lumiere,
    COUNT(*) AS nb_accidents
FROM analytics.accident_usagers_aggr aua
LEFT JOIN analytics.dim_lum ON aua.lum = dim_lum.lum
GROUP BY dim_lum.libelle
ORDER BY nb_accidents DESC;
```

---

## Vue Matérialisée

### `analytics.accident_usagers_aggr`

**Objectif** : Centraliser la jointure ACCIDENT → LIEUX → USAGER (agrégé) → DATE_ACCIDENT pour éviter de recalculer ces jointures coûteuses dans chaque requête.

### Structure

```sql
CREATE MATERIALIZED VIEW analytics.accident_usagers_aggr AS
SELECT
    a.num_acc,
    -- Caractéristiques de l'accident
    a.agg, a.circ, a.lum, a.atm, a.col AS code_collision,
    a.surf, a.prof, a.plan,

    -- Localisation
    l.reg_code, l.reg_name,
    l.dep_code, l.dep_name,
    l.com_code, l.com_name,
    l.catr, l.vosp,

    -- Temporalité
    d.an, d.mois, d.jour, d.hrmn,

    -- Agrégations usagers (depuis CTE)
    COALESCE(u.nb_usagers_total, 0) AS nb_usagers_total,
    COALESCE(u.nb_indemnes, 0) AS nb_indemnes,
    COALESCE(u.nb_tues, 0) AS nb_tues,
    COALESCE(u.nb_blesses, 0) AS nb_blesses,

    -- Véhicules
    COALESCE(v.nb_vehicules_impliques, 0) AS nb_vehicules_impliques
FROM ACCIDENT a
INNER JOIN LIEUX l USING (num_acc)
INNER JOIN DATE_ACCIDENT d USING (num_acc)
LEFT JOIN (
    SELECT num_acc,
        COUNT(*) AS nb_usagers_total,
        COUNT(*) FILTER (WHERE grav = 'Indemne') AS nb_indemnes,
        COUNT(*) FILTER (WHERE grav = 'Tué') AS nb_tues,
        COUNT(*) FILTER (WHERE grav = 'Blessé') AS nb_blesses
    FROM USAGER
    GROUP BY num_acc
) u USING (num_acc)
LEFT JOIN (
    SELECT num_acc, COUNT(DISTINCT vehicule_id) AS nb_vehicules_impliques
    FROM VEHICULE
    GROUP BY num_acc
) v USING (num_acc);
```

### Index Créés

```sql
CREATE INDEX idx_accident_usagers_aggr_reg ON analytics.accident_usagers_aggr (reg_code);
CREATE INDEX idx_accident_usagers_aggr_dep ON analytics.accident_usagers_aggr (dep_code);
CREATE INDEX idx_accident_usagers_aggr_com ON analytics.accident_usagers_aggr (com_code);
CREATE INDEX idx_accident_usagers_aggr_agg ON analytics.accident_usagers_aggr (agg);
CREATE INDEX idx_accident_usagers_aggr_catr ON analytics.accident_usagers_aggr (catr);
CREATE INDEX idx_accident_usagers_aggr_an_mois ON analytics.accident_usagers_aggr (an, mois);
CREATE INDEX idx_accident_usagers_aggr_lum_atm ON analytics.accident_usagers_aggr (lum, atm);
```

### Performances

| Opération | Sans Vue | Avec Vue | Gain |
|-----------|----------|----------|------|
| Agrégation régionale | 2-3s | 200ms | **10-15x** |
| Analyse temporelle | 3-5s | 300ms | **10-16x** |
| Requêtes complexes (z-score) | 5-10s | 1-2s | **5x** |

### Taille

- **Lignes** : ~476 000 (1 ligne = 1 accident)
- **Taille disque** : ~80-100 MB
- **Temps de création** : 30-90 secondes
- **Temps de rafraîchissement** : 30-90 secondes

---

## Utilisation avec Python

### Avec sql_loader.py

```python
from sql_loader import SQLQueryLoader
import pandas as pd
from sqlalchemy import create_engine

# Initialisation
loader = SQLQueryLoader(sql_dir='analytics/sql')
engine = create_engine('postgresql://user:password@localhost/db_accm')

# Charger une requête spécifique
query = loader.load_query('section1', '1.1')  # Top 10 régions
df = pd.read_sql(query, engine)

print(df.head())
```

### Sans sql_loader.py

```python
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine('postgresql://user:password@localhost/db_accm')

# Requête inline
query = """
SELECT
    reg_name,
    COUNT(*) AS nb_accidents,
    SUM(nb_tues) AS nb_tues
FROM analytics.accident_usagers_aggr
WHERE reg_code IS NOT NULL
GROUP BY reg_name
ORDER BY nb_accidents DESC
LIMIT 10;
"""

df = pd.read_sql(query, engine)
print(df)
```

### Mapping des Requêtes

| Section | Query ID | Description Python |
|---------|----------|-------------------|
| section1 | 1.1 | `loader.load_query('section1', '1.1')` |
| section1 | 1.2 | `loader.load_query('section1', '1.2')` |
| section2 | 2.1 | `loader.load_query('section2', '2.1')` |
| section3 | 3.1 | `loader.load_query('section3', '3.1')` |
| ... | ... | ... |

---

## Maintenance et Rafraîchissement

### Rafraîchir la Vue Matérialisée

Après chargement de nouvelles données dans les tables sources :

```bash
psql -U postgres -h localhost -d db_accm -f analytics/sql/refresh_matviews.sql
```

**Ou en SQL direct** :
```sql
REFRESH MATERIALIZED VIEW analytics.accident_usagers_aggr;
```

**Durée** : 30-90 secondes

### Vérifier la Cohérence

```sql
-- Vérifier que le nombre d'accidents correspond
SELECT COUNT(*) FROM ACCIDENT;
SELECT COUNT(*) FROM analytics.accident_usagers_aggr;

-- Vérifier que le nombre de tués correspond
SELECT SUM(CASE WHEN grav = 'Tué' THEN 1 ELSE 0 END) FROM USAGER;
SELECT SUM(nb_tues) FROM analytics.accident_usagers_aggr;
```

### Reconstruire les Index (après modifications massives)

```sql
REINDEX SCHEMA analytics;
```

---

## Liens Utiles

- [README analytics général](../README.md) - Vue d'ensemble du module analytics
- [README ETL](../../etl/README.md) - Pipeline de chargement des données sources
- [sql_loader.py](../sql_loader.py) - Utilitaire Python pour charger les requêtes

---

## Support et Contributions

Pour toute question ou suggestion d'amélioration, consulter le fichier CONTRIBUTING.md à la racine du projet.

---

**Mighty Mosquitoes** - Projet Simplon Data Engineer 2025
*Analyses des Accidents Corporels de la Circulation en France*
