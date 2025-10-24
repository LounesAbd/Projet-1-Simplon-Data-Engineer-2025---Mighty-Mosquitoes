# Module Analytics - Mighty Mosquitoes

## Vue d'ensemble

Ce module contient l'ensemble des analyses et visualisations sur les accidents corporels de la circulation en France. Il représente la couche analytique du projet Mighty Mosquitoes et fournit des KPI opérationnels, des analyses statistiques avancées et des outils de visualisation pour identifier les zones et conditions à risque.

## Architecture et Organisation

```
analytics/
├── README.md                           # Ce fichier
├── analy_accidents.ipynb              # Notebook principal avec données réelles
├── analyse_accidents_template.ipynb    # Template de développement (avec mock data puis données réelles)
├── mock_data.py                        # Générateur de données factices pour tests
├── sql_loader.py                       # Utilitaire pour charger les requêtes SQL
├── requetes.sql                        # Fichier monolithe historique (70KB)
└── sql/                                # Requêtes SQL refactorisées
    ├── README.md                       # Documentation détaillée des fichiers SQL
    ├── 00_header.sql                   # Header de connexion à la base
    ├── setup_dimensions.sql            # Tables de dimensions et vue matérialisée
    ├── section1_kpi_zones.sql          # KPI zones à risque (14 requêtes)
    ├── section2_kpi_conditions.sql     # KPI conditions de survenue (12 requêtes)
    ├── section3_kpi_tendances.sql      # Tendances temporelles (8 requêtes)
    ├── section4_conditions_risque.sql  # Analyses statistiques (3 requêtes)
    ├── section5_flux_graves.sql        # Zones fréquentées vs accidents graves (3 requêtes)
    ├── section6_anomalies_temporelles.sql # Détection d'anomalies (2 requêtes)
    ├── section7_optimisation.sql       # Scripts d'optimisation (non implémenté)
    ├── bonus_analyses_avancees.sql     # Requêtes bonus innovantes
    ├── bonus_vues_utiles.sql           # Vues de synthèse rapide
    └── refresh_matviews.sql            # Rafraîchissement des vues matérialisées
```

## Workflow de Développement

### Phase 1 : Préparation (Dépôt monolithe)
Développement initial dans [requetes.sql](requetes.sql) en attendant la réception de la base de données. Ce fichier monolithe contient toutes les requêtes brutes et a servi de base de travail pour la préparation des analyses.

### Phase 2 : Refactorisation SQL
Réorganisation du fichier monolithe en **sections thématiques modulaires** dans le dossier [sql/](sql/) pour améliorer la maintenabilité et la clarté :
- Section 1 : Zones à risque (régions, départements, communes, types de routes)
- Section 2 : Conditions de survenue (météo, luminosité, profils usagers)
- Section 3 : Tendances temporelles (séries temporelles, saisonnalité)
- Section 4 : Analyses statistiques (scores de risque, corrélations)
- Section 5 : Comparaison zones fréquentées / accidents graves
- Section 6 : Détection d'anomalies hebdomadaires et contextuelles

### Phase 3 : Prototypage avec Mock Data
Développement de [analyse_accidents_template.ipynb](analyse_accidents_template.ipynb) avec des **données factices** générées par [mock_data.py](mock_data.py). Cette approche a permis de :
- Tester différentes visualisations sans attendre la base de données
- Valider les présentations graphiques avant intégration

### Phase 4 : Intégration SQL Loader
Création de [sql_loader.py](sql_loader.py) pour **éliminer la duplication de code** :
- Parse automatiquement les fichiers SQL
- Extrait les requêtes individuelles par leur identifiant (ex: `1.1`, `2.3`)
- Permet d'utiliser les fichiers SQL comme source unique de vérité
- Cache les requêtes pour améliorer les performances

**Usage :**
```python
from sql_loader import SQLQueryLoader

loader = SQLQueryLoader()
query = loader.load_query('section1', '1.1')  # Charge la requête 1.1
df = pd.read_sql(query, engine)
```

### Phase 5 : Setup des Dimensions et Optimisations
Création de [setup_dimensions.sql](sql/setup_dimensions.sql) pour structurer la couche analytique :
- **Tables de dimensions** : normalisation des libellés métiers (agglomération, catégorie de route, luminosité, météo, etc.) -> **non utilisé**
- **Vue matérialisée** `analytics.accident_usagers_aggr` : jointure pré-calculée ACCIDENT → LIEUX → USAGER → DATE_ACCIDENT
- **7 index optimisés** pour accélérer les requêtes analytiques
- Validation automatique de cohérence des données

Début de réflexion sur optimisations avancées dans [section7_optimisation.sql](sql/section7_optimisation.sql) (partitionnement, index spécifiques) mais **non implémenté** par manque de temps suite à la réception tardive de la base de données.

### Phase 6 : Production avec Données Réelles
Suite à la réception de la base de données, refactorisation du template en [analy_accidents.ipynb](analytics/analy_accidents.ipynb) :
- Sélection des requêtes les plus pertinentes
- Intégration des vraies données
- Requêtes codées en dur dans le notebook pour éviter les rechargements constants lors des modifications des fichiers .sql

### Phase 7 : Analyses Avancées
Ajout de requêtes complexes dans [bonus_analyses_avancees.sql](sql/bonus_analyses_avancees.sql) :
- **"Cocktail mortel"** : analyse multi-facteurs (atmosphère × luminosité × route × heure × agglo) avec score de létalité et z-score
- **"Effet week-end saisonnier"** : croisement jour × mois × heure pour identifier les pics temporels dangereux
- **Vue d'ensemble** : KPI de synthèse rapide

## Guide d'Utilisation

### Prérequis
- PostgreSQL 12+
- Python 3.8+ avec les dépendances :
  - `pandas`
  - `numpy`
  - `matplotlib`
  - `seaborn`
  - `sqlalchemy`
  - `psycopg2`

### 1. Setup Initial de la Base de Données

Créer le schéma analytique et les tables de dimensions :
```bash
psql -U postgres -h localhost -d db_accm -f analytics/sql/setup_dimensions.sql
```

Cette commande va :
- Vérifier les prérequis (tables sources ACCIDENT, USAGER, LIEUX, DATE_ACCIDENT)
- Créer le schéma `analytics`
- Créer 6 tables de dimensions (dim_agg, dim_catr, dim_circ, dim_lum, dim_atm, dim_int)
- Créer la vue matérialisée `accident_usagers_aggr` (30-90 secondes)
- Créer 7 index optimisés
- Valider la cohérence des données

### 2. Exécution des Requêtes SQL

Exécuter une section spécifique :
```bash
psql -U postgres -h localhost -d db_accm -f analytics/sql/section1_kpi_zones.sql
```

Rafraîchir la vue matérialisée après chargement de nouvelles données :
```bash
psql -U postgres -h localhost -d db_accm -f analytics/sql/refresh_matviews.sql
```

### 3. Utilisation des Notebooks

**Option A : Notebook de production (données réelles)**
```bash
jupyter notebook analytics/analy_accidents.ipynb
```

**Option B : Template de développement (mock data ou données réelles)**
```bash
jupyter notebook analytics/analyse_accidents_template.ipynb
```

Pour basculer entre mock data et vraies données, modifier la variable dans le notebook :
```python
USE_MOCK_DATA = False  # False pour données réelles, True pour mock
```

### 4. Utilisation du SQL Loader

Dans un notebook ou script Python :
```python
from sql_loader import SQLQueryLoader
import pandas as pd
from sqlalchemy import create_engine

# Initialisation
loader = SQLQueryLoader(sql_dir='sql')
engine = create_engine('postgresql://user:password@localhost/db_accm')

# Charger et exécuter une requête
query = loader.load_query('section1', '1.1')
df = pd.read_sql(query, engine)

# Lister toutes les requêtes disponibles d'une section
queries = loader._parse_section_file('section1')
print(f"Requêtes disponibles : {', '.join(queries.keys())}")
```

## Contenu des Analyses

### Section 1 : Zones à Risque (14 requêtes)
- Top régions/départements/communes les plus accidentogènes
- Analyse par type de route (autoroute, nationale, départementale, communale)
- Comparaison agglo vs hors agglo
- Régime de circulation et impact sur la gravité

**KPI prioritaires :**
- Nombre d'accidents par région
- Taux de mortalité par département
- Zones à risque élevé (concentration d'accidents mortels)

### Section 2 : Conditions de Survenue (12 requêtes)
- Impact des conditions météorologiques
- Analyse de la luminosité (jour/nuit, éclairage public)
- Profils usagers (âge, sexe, catégorie de véhicule)
- Surface de chaussée et état de la route

**KPI prioritaires :**
- Accidents par conditions météo
- Surmortalité nocturne
- Profils usagers les plus vulnérables

### Section 3 : Tendances Temporelles (8 requêtes)
- Évolution mensuelle et annuelle
- Saisonnalité des accidents
- Analyse par jour de la semaine
- Tranches horaires à risque

**KPI prioritaires :**
- Tendance annuelle (en hausse/baisse ?)
- Mois/jours les plus dangereux
- Heures de pointe accidentogènes

### Section 4 : Conditions à Risque (3 requêtes)
- Scores de risque par combinaison de facteurs
- Corrélations entre variables
- Analyse statistique des facteurs aggravants

### Section 5 : Zones Fréquentées vs Accidents Graves (3 requêtes)
- Comparaison volume d'accidents vs gravité
- Identification des "points noirs"
- Zones à fort trafic vs zones à forte létalité

### Section 6 : Détection d'Anomalies Temporelles (2 requêtes)
- Analyse hebdomadaire avec z-score
- Détection d'anomalies contextuelles
- Pics inhabituels d'accidents

### Bonus : Analyses Avancées
- **Cocktail mortel** : combinaisons multi-facteurs à haut risque avec score de dangerosité
- **Effet week-end saisonnier** : croisement temporel complexe pour identifier les périodes critiques
- **Vues de synthèse** : KPI globaux pour tableau de bord

## Notes Techniques

### Tables de Dimensions
Le schéma `analytics` contient 6 tables de dimensions pour normaliser les libellés :

| Table | Champ | Description |
|-------|-------|-------------|
| `dim_agg` | agg | Type d'agglomération (en/hors agglo) |
| `dim_catr` | catr | Catégorie de route (autoroute, nationale, etc.) |
| `dim_circ` | circ | Régime de circulation (sens unique, bidirectionnelle, etc.) |
| `dim_lum` | lum | Conditions de luminosité (jour, nuit, crépuscule) |
| `dim_atm` | atm | Conditions atmosphériques (normale, pluie, neige, etc.) |
| `dim_int` | ints | Type d'intersection (X, T, Y, giratoire, etc.) |

### Vue Matérialisée
`analytics.accident_usagers_aggr` centralise la jointure des 4 tables principales :
- ACCIDENT
- LIEUX
- USAGER (agrégé par accident)
- DATE_ACCIDENT

**Champs calculés :**
- `nb_usagers_total`, `nb_indemnes`, `nb_tues`, `nb_blesses`
- `nb_vehicules_impliques`

**Avantages :**
- Gain de performance : pré-calcul des agrégations
- Simplicité : requêtes plus lisibles
- Cohérence : source unique pour toutes les analyses

**Maintenance :**
Rafraîchir après chargement de nouvelles données :
```sql
REFRESH MATERIALIZED VIEW analytics.accident_usagers_aggr;
```

### Index Créés
7 index pour optimiser les requêtes fréquentes :
- `reg_code`, `dep_code`, `com_code` (agrégations géographiques)
- `agg`, `catr` (filtres sur type de lieu/route)
- `(an, mois)` (séries temporelles)
- `(lum, atm)` (analyses de conditions)

### Performance
**non testée***

## Points d'Attention et Améliorations Futures

### Limites Actuelles
1. **Section 7 (Optimisation)** non implémentée faute de temps
   - Partitionnement temporel de la vue matérialisée
   - Index spécifiques supplémentaires
   - Analyse des plans d'exécution

2. **Requêtes codées en dur** dans `analy_accidents.ipynb`
   - Nécessaire pour éviter les rechargements constants / contrainte de temps
   - Création d'un décalage avec les fichiers .sql
   - À synchroniser manuellement

3. **Tests de cohérence** non automatisés
   - Validation manuelle des agrégations
   - Pas de tests unitaires sur les requêtes

### Améliorations Proposées
1. **Automatisation**
   - Pipeline de tests pour valider les requêtes
   - Script de synchronisation notebook ↔ fichiers SQL
   - CI/CD pour vérifier la cohérence

2. **Performance**
   - Implémenter le partitionnement de `accident_usagers_aggr`
   - Ajouter des index covering pour les requêtes complexes
   - Analyser et optimiser les requêtes les plus lentes

3. **Fonctionnalités**
   - Dashboard interactif (Plotly Dash / Streamlit)
   - API REST pour exposer les KPI
   - Export automatisé des résultats (CSV, Excel, PDF)

4. **Documentation**
   - Ajouter des exemples de visualisations pour chaque section
   - Documenter les choix métier et seuils de gravité
   - Créer un guide d'interprétation des résultats

## Liens Utiles

- [Documentation SQL détaillée](sql/README.md) - Description complète des fichiers SQL
- [Documentation ETL](../etl/README.md) - Pipeline de chargement des données
- Documentation projet principale - Vue d'ensemble du projet Mighty Mosquitoes

---

**Mighty Mosquitoes** - Projet Simplon Data Engineer 2025
