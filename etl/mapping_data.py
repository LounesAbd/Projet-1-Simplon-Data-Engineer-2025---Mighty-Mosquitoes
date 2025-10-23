"""Mapping dictionaries for the accident dataset categorical codes.

seul int est un chiffre de 1 à 9
"attention pour 6, 11, 13 : nous n'avons que le 1er mot : à confirmer"
"attention bcp de se deplacant dans le csv"
attention CATV : détermination VL, VU, PL pour vehicule leger, vehicule unitaire, Poids lourd ect...

"""


LUM = {
    1: "Plein jour",
    2: "Crépuscule ou aube",
    3: "Nuit sans éclairage public",
    4: "Nuit avec éclairage public non allumé",
    5: "Nuit avec éclairage public allumé",
}

AGG = {
    1: "Hors agglomération",
    2: "En agglomération",
}

INT = {
    1: "Hors intersection",
    2: "Intersection en X",
    3: "Intersection en T",
    4: "Intersection en Y",
    5: "Intersection à plus de 4 branches",
    6: "Giratoire",
    7: "Place",
    8: "Passage à niveau",
    9: "Autre intersection",
}

ATM = {
    1: "Normale",
    2: "Pluie légère",
    3: "Pluie forte",
    4: "Neige ou grêle",
    5: "Brouillard ou fumée",
    6: "Vent fort ou tempête",
    7: "Temps éblouissant",
    8: "Temps couvert",
    9: "Autre",
}

COL = {
    1: "Deux véhicules - frontale",
    2: "Deux véhicules - par l’arrière",
    3: "Deux véhicules - par le côté",
    4: "Trois véhicules et plus - en chaîne",
    5: "Trois véhicules et plus - collisions multiples",
    6: "Autre collision",
    7: "Sans collision",
}

GPS = {
    "M": "Métropole",
    "A": "Antilles (Martinique ou Guadeloupe)",
    "G": "Guyane",
    "R": "Réunion",
    "Y": "Mayotte",
}

CATR = {
    1: "Autoroute",
    2: "Route nationale",
    3: "Route départementale",
    4: "Voie communale",
    5: "Hors réseau public",
    6: "Parc de stationnement ouvert à la circulation publique",
    9: "Autre",
}

CIRC = {
    1: "À sens unique",
    2: "Bidirectionnelle",
    3: "À chaussées séparées",
    4: "Avec voies d’affectation variable",
}

VOSP = {
    1: "Piste cyclable",
    2: "Bande cyclable",
    3: "Voie réservée",
}

PROF = {
    1: "Plat",
    2: "Pente",
    3: "Sommet de côte",
    4: "Bas de côte",
}

PLAN = {
    1: "Partie rectiligne",
    2: "En courbe à gauche",
    3: "En courbe à droite",
    4: "En S",
}

SURF = {
    1: "Normale",
    2: "Mouillée",
    3: "Flaques",
    4: "Inondée",
    5: "Enneigée",
    6: "Boue",
    7: "Verglacée",
    8: "Corps gras ou huile",
    9: "Autre",
}

INFRA = {
    1: "Souterrain ou tunnel",
    2: "Pont ou autopont",
    3: "Bretelle d’échangeur ou de raccordement",
    4: "Voie ferrée",
    5: "Carrefour aménagé",
    6: "Zone piétonne",
    7: "Zone de péage",
}

SITU = {
    1: "Sur chaussée",
    2: "Sur bande d’arrêt d’urgence",
    3: "Sur accotement",
    4: "Sur trottoir",
    5: "Sur piste cyclable",
}

SENC = {
    1: "PK ou PR ou numéro d'adresse postale croissant",
    2: "PK ou PR ou numéro d'adresse postale décroissant",
}
#VL seul, PL seul 3 ou > 3, VU
CATV = {
    1: "Bicyclette",
    2: "Cyclomoteur < 50 cm³",
    3: "Voiturette (quadricycle à moteur carrossé)",
    4: "Scooter immatriculé (code obsolète depuis 2006)",
    5: "Motocyclette (code obsolète depuis 2006)",
    6: "Side-car (code obsolète depuis 2006)",
    7: "Véhicule léger seul",
    8: "Véhicule léger + caravane (code obsolète)",
    9: "Véhicule léger + remorque (code obsolète)",
    10: "Véhicule utilitaire seul 1,5T <= PTAC <= 3,5T",
    11: "Véhicule utilitaire + caravane (code obsolète)",
    12: "Véhicule utilitaire + remorque (code obsolète)",
    13: "Poids lourd seul 3,5T < PTAC <= 7,5T",
    14: "Poids lourd seul > 7,5T",
    15: "Poids lourd > 3,5T + remorque",
    16: "Tracteur routier seul",
    17: "Tracteur routier + semi-remorque",
    18: "Transport en commun (code obsolète depuis 2006)",
    19: "Tramway (code obsolète depuis 2006)",
    20: "Engin spécial",
    21: "Tracteur agricole",
    30: "Scooter < 50 cm³",
    31: "Motocyclette > 50 cm³ et <= 125 cm³",
    32: "Scooter > 50 cm³ et <= 125 cm³",
    33: "Motocyclette > 125 cm³",
    34: "Scooter > 125 cm³",
    35: "Quad léger <= 50 cm³",
    36: "Quad lourd > 50 cm³",
    37: "Autobus",
    38: "Autocar",
    39: "Train",
    40: "Tramway",
    99: "Autre véhicule",
}
#"attention pour 6, 11, 13 : nous n'avons que le 1er mot : à confirmer"
OBS = {
    1: "Véhicule en stationnement",
    2: "Arbre",
    3: "Glissière métallique",
    4: "Glissière béton",
    5: "Autre glissière",
    6: "Bâtiment, mur, pile de pont",
    7: "Support de signalisation verticale ou borne d’appel d’urgence",
    8: "Poteau",
    9: "Mobilier urbain",
    10: "Parapet",
    11: "Îlot, refuge, borne haute",
    12: "Bordure de trottoir",
    13: "Fossé, talus ou paroi rocheuse",
    14: "Autre obstacle fixe sur chaussée",
    15: "Autre obstacle fixe sur trottoir ou accotement",
    16: "Sortie de chaussée sans obstacle",
}

OBSM = {
    1: "Piéton",
    2: "Véhicule",
    4: "Véhicule sur rail",
    5: "Animal domestique",
    6: "Animal sauvage",
    9: "Autre",
}

CHOC = {
    1: "Avant",
    2: "Avant droit",
    3: "Avant gauche",
    4: "Arrière",
    5: "Arrière droit",
    6: "Arrière gauche",
    7: "Côté droit",
    8: "Côté gauche",
    9: "Chocs multiples (tonneaux)",
}

MANV = {
    1: "Sans changement de direction",
    2: "Même sens, même file",
    3: "Entre deux files",
    4: "En marche arrière",
    5: "À contresens",
    6: "En franchissant le terre-plein central",
    7: "Dans le couloir bus, dans le même sens",
    8: "Dans le couloir bus, dans le sens inverse",
    9: "En s’insérant",
    10: "En faisant demi-tour sur la chaussée",
    11: "Changement de file à gauche",
    12: "Changement de file à droite",
    13: "Déporté à gauche",
    14: "Déporté à droite",
    15: "Tournant à gauche",
    16: "Tournant à droite",
    17: "Dépassement à gauche",
    18: "Dépassement à droite",
    19: "Traversant la chaussée",
    20: "Manœuvre de stationnement",
    21: "Manœuvre d’évitement",
    22: "Ouverture de porte",
    23: "Arrêté (hors stationnement)",
    24: "En stationnement (avec occupants)",
}

CATU = {
    1: "Conducteur",
    2: "Passager",
    3: "Piéton",
    4: "Piéton en roller ou en trottinette",
}

GRAV = {
    1: "Indemne",
    2: "Tué",
    3: "Blessé hospitalisé",
    4: "Blessé léger",
}

SEXE = {
    1: "Masculin",
    2: "Féminin",
}

TRAJET = {
    1: "Domicile - travail",
    2: "Domicile - école",
    3: "Courses ou achats",
    4: "Utilisation professionnelle",
    5: "Promenade - loisirs",
    9: "Autre",
}

SECU = {
    1: "Ceinture",
    2: "Casque",
    3: "Dispositif enfants",
    4: "Équipement réfléchissant",
    9: "Autre",
}

SECU_UTL = {
    1: "Oui",
    2: "Non",
    3: "Non déterminable",
}

LOPC = {
    1: "Sur chaussée - A + 50 m du passage piéton",
    2: "Sur chaussée - A - 50 m du passage piéton",
    3: "Sur passage piéton - Sans signalisation lumineuse",
    4: "Sur passage piéton - Avec signalisation lumineuse",
    5: "Divers - Sur trottoir",
    6: "Divers - Sur accotement",
    7: "Divers - Sur refuge ou BAU",
    8: "Divers - Sur contre allée",
}



#"attention bcp de "se deplacant" dans le csv"
ACTP = {
    0: "Non renseigné ou sans objet",
    1: "Se déplaçant - sens du véhicule heurtant",
    2: "Se déplaçant - sens inverse du véhicule heurtant",
    3: "Traversant",
    4: "Masqué",
    5: "Jouant ou courant",
    6: "Avec animal",
    9: "Autre",
}

ETATP = {
    1: "Seul",
    2: "Accompagné",
    3: "En groupe",
}

MAPPING_DATA = {
    "lum": LUM,
    "agg": AGG,
    "int": INT,
    "atm": ATM,
    "col": COL,
    "gps": GPS,
    "catr": CATR,
    "circ": CIRC,
    "vosp": VOSP,
    "prof": PROF,
    "plan": PLAN,
    "surf": SURF,
    "infra": INFRA,
    "situ": SITU,
    "senc": SENC,
    "catv": CATV,
    "obs": OBS,
    "obsm": OBSM,
    "choc": CHOC,
    "manv": MANV,
    "catu": CATU,
    "grav": GRAV,
    "sexe": SEXE,
    "trajet": TRAJET,
    "secu": SECUT,
    "secu_utl": SECU_UTL,
    "lopc": LOPC,
    "actp": ACTP,
    "etatp": ETATP,
}

__all__ = [
    "LUM",
    "AGG",
    "INT",
    "ATM",
    "COL",
    "GPS",
    "CATR",
    "CIRC",
    "VOSP",
    "PROF",
    "PLAN",
    "SURF",
    "INFRA",
    "SITU",
    "SENC",
    "CATV",
    "OBS",
    "OBSM",
    "CHOC",
    "MANV",
    "CATU",
    "GRAV",
    "SEXE",
    "TRAJET",
    "SECU",
    "SECU_UTL",
    "LOPC",
    "ACTP",
    "ETATP",
    "MAPPING_DATA",
]
