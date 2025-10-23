"""
Générateur de données mockées réalistes pour le notebook d'analyse.

Ce fichier génère des DataFrames factices avec des structures identiques
aux requêtes SQL réelles, permettant de tester les visualisations sans
avoir besoin d'une base de données.

Usage:
    from mock_data import generate_mock_data
    MOCK_DATA = generate_mock_data()
    df_1_1 = MOCK_DATA['1_1']  # Top régions

Suppression:
    Une fois la base de données implémentée, vous pouvez supprimer ce fichier
    et basculer USE_MOCK_DATA = False dans le notebook.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# Seed pour reproductibilité
np.random.seed(42)

# ============================================================
# DONNÉES DE RÉFÉRENCE RÉALISTES
# ============================================================

REGIONS_FR = [
    'Île-de-France', 'Auvergne-Rhône-Alpes', 'Provence-Alpes-Côte d\'Azur',
    'Nouvelle-Aquitaine', 'Occitanie', 'Hauts-de-France', 'Grand Est',
    'Pays de la Loire', 'Bretagne', 'Normandie', 'Bourgogne-Franche-Comté',
    'Centre-Val de Loire'
]

DEPARTEMENTS_FR = [
    ('Paris', '75'), ('Bouches-du-Rhône', '13'), ('Nord', '59'),
    ('Rhône', '69'), ('Alpes-Maritimes', '06'), ('Haute-Garonne', '31'),
    ('Gironde', '33'), ('Loire-Atlantique', '44'), ('Hérault', '34'),
    ('Bas-Rhin', '67'), ('Yvelines', '78'), ('Isère', '38'),
    ('Var', '83'), ('Seine-Maritime', '76'), ('Ille-et-Vilaine', '35')
]

COMMUNES_FR = [
    'Paris', 'Marseille', 'Lyon', 'Toulouse', 'Nice', 'Nantes',
    'Strasbourg', 'Montpellier', 'Bordeaux', 'Lille', 'Rennes',
    'Reims', 'Le Havre', 'Saint-Étienne', 'Toulon', 'Grenoble',
    'Dijon', 'Angers', 'Nîmes', 'Villeurbanne'
]

CONDITIONS_LUMIERE = [
    'Plein jour', 'Crépuscule ou aube', 'Nuit sans éclairage public',
    'Nuit avec éclairage public allumé', 'Nuit avec éclairage public éteint'
]

CONDITIONS_METEO = [
    'Normale', 'Pluie légère', 'Pluie forte', 'Neige - grêle',
    'Brouillard - fumée', 'Vent fort - tempête', 'Temps éblouissant',
    'Temps couvert'
]

TYPES_AGGLOMERATION = ['En agglomération', 'Hors agglomération']

JOURS_SEMAINE = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche']


# ============================================================
# FONCTIONS DE GÉNÉRATION PAR SECTION
# ============================================================

def _mock_1_1_top_regions():
    """Mock 1.1 : Top 10 régions les plus accidentogènes."""
    # Données cohérentes avec réalité : Île-de-France en tête
    nb_accidents = [78523, 65432, 58921, 52341, 49876, 45678, 42156, 39854, 37234, 35123]

    return pd.DataFrame({
        'reg_name': REGIONS_FR[:10],
        'nb_accidents': nb_accidents
    })


def _mock_1_2_top_departements():
    """Mock 1.2 : Top 15 départements (taux de gravité)."""
    n = 15
    dep_names = [d[0] for d in DEPARTEMENTS_FR[:n]]

    # Générer des nombres cohérents
    tues = np.random.randint(150, 800, n)
    hosp = tues * np.random.randint(8, 15, n)  # 8-15x plus de blessés hospitalisés
    legers = hosp * np.random.uniform(1.5, 3, n).astype(int)
    indemnes = (tues + hosp + legers) * np.random.uniform(0.5, 1.5, n).astype(int)

    return pd.DataFrame({
        'dep_name': dep_names,
        'tues': tues,
        'hosp': hosp,
        'legers': legers,
        'indemnes': indemnes
    }).sort_values('tues', ascending=False)


def _mock_2_1_agglomeration():
    """Mock 2.1 : Répartition accidents par agglomération."""
    # ~65% en agglo, ~35% hors agglo (cohérent avec réalité)
    return pd.DataFrame({
        'agglomeration': TYPES_AGGLOMERATION,
        'nb_accidents': [310245, 165666]  # Total ~476k accidents
    })


def _mock_2_2_luminosite_atmosphere():
    """Mock 2.2 : Heatmap Luminosité × Atmosphère."""
    # Générer toutes les combinaisons
    data = []
    for lum in CONDITIONS_LUMIERE:
        for meteo in CONDITIONS_METEO:
            # Plus d'accidents en conditions normales
            if 'Normale' in meteo and 'Plein jour' in lum:
                nb = np.random.randint(80000, 120000)
            elif 'Normale' in meteo:
                nb = np.random.randint(40000, 80000)
            elif 'Plein jour' in lum:
                nb = np.random.randint(30000, 60000)
            else:
                nb = np.random.randint(5000, 30000)

            data.append({
                'luminosite': lum,
                'atmosphere': meteo,
                'nb_accidents': nb
            })

    return pd.DataFrame(data)


def _mock_3_1_evolution_annuelle():
    """Mock 3.1 : Évolution annuelle des accidents."""
    # Tendance décroissante cohérente avec réalité française
    annees = list(range(2012, 2020))
    nb_accidents = [64028, 62155, 59789, 58027, 56982, 55837, 54254, 52442]
    nb_tues = [3653, 3461, 3388, 3461, 3456, 3448, 3259, 3239]

    # Calcul de la tendance (régression linéaire simple)
    x = np.array(range(len(annees)))
    y = np.array(nb_accidents)
    coeffs = np.polyfit(x, y, 1)  # Régression linéaire (degré 1)
    tendance = np.polyval(coeffs, x)

    return pd.DataFrame({
        'annee': annees,
        'nb_accidents': nb_accidents,
        'nb_tues': nb_tues,
        'tendance': tendance.astype(int)
    })


def _mock_3_2_heatmap_jour_heure():
    """Mock 3.2 : Heatmap jour × heure."""
    data = []

    for jour in range(1, 8):  # 1=Lundi, 7=Dimanche
        for heure in range(24):
            # Pattern réaliste : pics 8h-9h, 12h-14h, 17h-19h
            if heure in [8, 9, 17, 18]:  # Heures de pointe
                base = 3500
            elif heure in [12, 13]:  # Pause déjeuner
                base = 2800
            elif 6 <= heure <= 22:  # Journée
                base = 2000
            else:  # Nuit
                base = 800

            # Plus d'accidents vendredi/samedi soir
            if jour in [5, 6] and 18 <= heure <= 23:
                base *= 1.3

            # Moins d'accidents dimanche matin
            if jour == 7 and heure < 10:
                base *= 0.6

            nb = int(base + np.random.normal(0, base * 0.15))

            data.append({
                'jour': jour,
                'heure': heure,
                'nb_accidents': max(100, nb)  # Minimum 100
            })

    return pd.DataFrame(data)


def _mock_4_1_quadrant_risque():
    """Mock 4.1 : Quadrant de risque (Fréquence × Gravité)."""
    conditions = CONDITIONS_METEO[:8]

    # Fréquence inversement proportionnelle à gravité (généralement)
    frequences = [280000, 85000, 35000, 22000, 18000, 12000, 8000, 5000]
    gravites = [0.012, 0.018, 0.028, 0.035, 0.022, 0.042, 0.015, 0.038]

    return pd.DataFrame({
        'condition': conditions,
        'frequence': frequences,
        'gravite_moyenne': gravites
    })


def _mock_5_1_top_communes():
    """Mock 5.1 : Top 20 communes."""
    n = 20
    communes = COMMUNES_FR[:n]

    # Paris largement en tête
    nb_accidents = [18500] + list(np.random.randint(3000, 8000, n-1))
    nb_tues = [np.random.randint(20, 150) for _ in range(n)]

    # Départements associés (simplifiés)
    deps = ['Paris', 'Bouches-du-Rhône', 'Rhône', 'Haute-Garonne', 'Alpes-Maritimes'] * 4

    return pd.DataFrame({
        'com_name': communes,
        'dep_name': deps[:n],
        'nb_accidents': nb_accidents,
        'nb_tues': nb_tues
    }).sort_values('nb_accidents', ascending=False)


def _mock_6_1_zscore_temporel():
    """Mock 6.1 : Z-score temporel (détection d'anomalies)."""
    data = []

    # Moyenne mensuelle : ~5500 accidents/mois
    moyenne_base = 5500
    ecart_type_base = 450

    for an in range(2012, 2020):
        for mois in range(1, 13):
            # Calculer moyenne et écart-type pour ce mois (historique)
            moyenne = moyenne_base + np.random.normal(0, 200)
            ecart_type = ecart_type_base + np.random.normal(0, 50)

            # Valeur observée
            nb_accidents = int(moyenne + np.random.normal(0, ecart_type))

            # Ajouter quelques anomalies (été 2015, hiver 2018)
            if (an == 2015 and mois in [7, 8]) or (an == 2018 and mois in [12]):
                nb_accidents = int(moyenne + 3 * ecart_type)  # Anomalie positive
            elif an == 2016 and mois == 2:
                nb_accidents = int(moyenne - 2.5 * ecart_type)  # Anomalie négative

            # Calcul z-score
            z_score = (nb_accidents - moyenne) / ecart_type if ecart_type > 0 else 0

            # Créer la date (premier jour du mois)
            date = pd.Timestamp(year=an, month=mois, day=1)

            # Détecter les anomalies (|z-score| > 2)
            anomalie = abs(z_score) > 2

            data.append({
                'date': date,
                'an': an,
                'mois': mois,
                'nb_accidents': nb_accidents,
                'moyenne': round(moyenne, 2),
                'ecart_type': round(ecart_type, 2),
                'z_score': round(z_score, 2),
                'anomalie': anomalie
            })

    return pd.DataFrame(data)


# ============================================================
# FONCTION PRINCIPALE
# ============================================================

def generate_mock_data():
    """
    Génère tous les DataFrames mockés pour le notebook.

    Returns:
        dict: Dictionnaire {clé: DataFrame} où clé = '1_1', '1_2', etc.

    Example:
        >>> MOCK_DATA = generate_mock_data()
        >>> df_regions = MOCK_DATA['1_1']
        >>> print(df_regions.head())
    """
    print("🔧 Génération des données mockées...")

    mock_data = {
        '1_1': _mock_1_1_top_regions(),
        '1_2': _mock_1_2_top_departements(),
        '2_1': _mock_2_1_agglomeration(),
        '2_2': _mock_2_2_luminosite_atmosphere(),
        '3_1': _mock_3_1_evolution_annuelle(),
        '3_2': _mock_3_2_heatmap_jour_heure(),
        '4_1': _mock_4_1_quadrant_risque(),
        '5_1': _mock_5_1_top_communes(),
        '6_1': _mock_6_1_zscore_temporel(),
    }

    # Statistiques de génération
    total_rows = sum(len(df) for df in mock_data.values())
    print(f"✅ {len(mock_data)} DataFrames générés ({total_rows:,} lignes au total)")
    print()
    print("📊 Résumé:")
    for key, df in mock_data.items():
        print(f"   - Mock {key}: {len(df):,} lignes, {len(df.columns)} colonnes")

    return mock_data


# ============================================================
# TESTS RAPIDES
# ============================================================

if __name__ == '__main__':
    # Test de génération
    print("=" * 60)
    print("TEST DE GÉNÉRATION DES DONNÉES MOCKÉES")
    print("=" * 60)
    print()

    mock_data = generate_mock_data()

    print()
    print("=" * 60)
    print("APERÇU DES DONNÉES GÉNÉRÉES")
    print("=" * 60)

    # Aperçu 1.1
    print()
    print("📍 Mock 1.1 - Top régions:")
    print(mock_data['1_1'].head())

    # Aperçu 3.1
    print()
    print("📅 Mock 3.1 - Évolution annuelle:")
    print(mock_data['3_1'])

    # Aperçu 6.1 avec anomalies
    print()
    print("🚨 Mock 6.1 - Anomalies détectées (|z-score| > 2):")
    df_6_1 = mock_data['6_1']
    anomalies = df_6_1[df_6_1['z_score'].abs() > 2]
    print(f"   {len(anomalies)} anomalies trouvées")
    if len(anomalies) > 0:
        print(anomalies[['an', 'mois', 'nb_accidents', 'z_score']].head())

    print()
    print("=" * 60)
    print("✅ Génération réussie - Prêt pour utilisation dans le notebook")
    print("=" * 60)
