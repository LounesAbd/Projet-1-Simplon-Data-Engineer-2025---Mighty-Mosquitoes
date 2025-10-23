import os
import yaml
import pandas as pd
import requests
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from dotenv import load_dotenv
from pathlib import Path
from sqlalchemy.exc import SQLAlchemyError


load_dotenv()


try:
    ROOT_DIR = Path(__file__).resolve().parents[1]
except NameError:
    ROOT_DIR = Path.cwd().parent

CONFIG_PATH = ROOT_DIR / "config.yml"
SQL_FILES_PATH = ROOT_DIR / "etl"
print(CONFIG_PATH)
print(SQL_FILES_PATH)



def load_config(path):
    with open(path, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)
        
    for section, values in config.items():
        for key, val in values.items():
            if isinstance(val, str) and val.startswith("${"):
                env_var = val.strip("${}")
                config[section][key] = os.getenv(env_var)    
    return config


conf = load_config(CONFIG_PATH)
db_conf = conf['database']
sql_file_conf = conf['sqlfile']



def test_postgres_connection(db_config: dict, db_name: str | None = None) -> str:
    """
    Teste la connexion à une base PostgreSQL et retourne un message lisible.

    Args:
        db_config (dict): Dictionnaire contenant les informations de connexion :
            - user : nom d'utilisateur PostgreSQL
            - password : mot de passe
            - host : adresse du serveur
            - port : port PostgreSQL
            - db_default : base par défaut (souvent 'postgres')
        db_name (str | None): Nom de la base à tester. Si None, utilise db_config['db_default'].

    Returns:
        str: Message de succès avec la version PostgreSQL ou message d'erreur.
    """

    # Choix de la base : soit celle fournie, soit la base par défaut
    db_to_use = db_name or db_config["db_default"]

    # Création de l'URL de connexion PostgreSQL compatible SQLAlchemy
    db_url = (
        f"postgresql+psycopg2://{db_config['user']}:{db_config['password']}"
        f"@{db_config['host']}:{db_config['port']}/{db_to_use}"
    )

    try:
        # Création de l'engine SQLAlchemy
        engine = create_engine(db_url)

        # Ouverture de la connexion
        with engine.connect() as conn:
            # Exécution d'une requête pour récupérer la version PostgreSQL
            version = conn.execute(text("SELECT version();")).scalar()

            # Message de succès
            message = (
                f"Connexion réussie à la base '{db_to_use}'."
                f"Version PostgreSQL : {version}"
            )
            return message

    except SQLAlchemyError as e:
        # Gestion des erreurs de connexion
        message = (
            f"Erreur de connexion à la base '{db_to_use}'."
            f"{e}"
        )
        return message

    finally:
        # Fermeture propre de l'engine
        if 'engine' in locals():
            engine.dispose()

# execution
test_postgres_connection(db_conf)


def create_database(db_config: dict, db_name: str):
    """
    Vérifie si une base PostgreSQL existe et la crée si nécessaire.

    Args:
        db_config (dict): Dictionnaire contenant les informations de connexion :
            - user : nom d'utilisateur PostgreSQL
            - password : mot de passe
            - host : adresse du serveur
            - port : port PostgreSQL
            - db_default : base par défaut utilisée pour se connecter initialement
        db_name (str): Nom de la base à créer ou vérifier.

    Returns:
        None
    """

    # Construction de l'URL de connexion sur la base par défaut (souvent 'postgres')
    db_url = (
        f"postgresql+psycopg2://{db_config['user']}:{db_config['password']}"
        f"@{db_config['host']}:{db_config['port']}/{db_config['db_default']}"
    )
    try:
        # Création de l'engine avec autocommit pour exécuter CREATE DATABASE
        engine = create_engine(db_url, isolation_level="AUTOCOMMIT")

        with engine.connect() as conn:
            # Vérifier si la base existe déjà
            result = conn.execute(
                text("SELECT 1 FROM pg_database WHERE datname = :dbname"),
                {"dbname": db_name}
            )
            exists = result.scalar()  # Récupère le premier résultat (1 si la base existe)

            if not exists:
                # Crée la base si elle n'existe pas
                conn.execute(text(f'CREATE DATABASE "{db_name}"'))
                print(f"Base '{db_name}' créée.")
            else:
                print(f"Base '{db_name}' existe déjà.")
    except SQLAlchemyError as e:
        # Gestion des erreurs SQLAlchemy
        print(f"Erreur lors de la vérification ou création de la base : {e}")

    finally:
        # Fermeture propre de l'engine
        if 'engine' in locals():
            engine.dispose()


# execution
create_database(db_conf, db_conf["db_accm"])

def execute_sql_file(db_conf: dict, db_name: str, sql_file_path: str) -> str:

    db_to_use = db_name
    sql_file = Path(sql_file_path)
    if not sql_file.is_file():
        return f"Fichier SQL introuvable : {sql_file_path}"
    db_url = (
        f"postgresql+psycopg2://{db_conf['user']}:{db_conf['password']}"
        f"@{db_conf['host']}:{db_conf['port']}/{db_to_use}"
    )
    try:
        engine = create_engine(db_url, isolation_level="AUTOCOMMIT")

        # Lire le contenu du fichier SQL
        sql_commands = sql_file.read_text(encoding="utf-8")

        with engine.connect() as conn:
            conn.execute(text(sql_commands))
        return f"Fichier SQL '{sql_file_path}' exécuté avec succès sur la base '{db_to_use}'."
    except SQLAlchemyError as e:
        return f"Erreur lors de l'exécution du fichier SQL : {e}"
    finally:
        if 'engine' in locals():
            engine.dispose()
execute_sql_file(db_conf, db_conf["db_accm"], SQL_FILES_PATH/sql_file_conf["file_1"])


def execute_sql_to_df(db_conf: dict, db_name: str, sql_file_path: str) -> pd.DataFrame:
    """
    Exécute une requête SQL depuis un fichier sur une base PostgreSQL et retourne le résultat sous forme de DataFrame.

    Args:
        db_conf (dict): Dictionnaire contenant les informations de connexion :
            - user : nom d'utilisateur PostgreSQL
            - password : mot de passe
            - host : adresse du serveur
            - port : port PostgreSQL
            - db_default : base par défaut (optionnelle)
        db_name (str): Nom de la base de données sur laquelle exécuter la requête.
        sql_file_path (str): Chemin vers le fichier SQL contenant la ou les requêtes.

    Returns:
        pd.DataFrame: DataFrame contenant le résultat de la requête si des colonnes existent,
                      sinon un DataFrame avec un message d'information.
    """
    # Convertit le chemin du fichier SQL en objet Path pour faciliter les manipulations
    sql_file = Path(sql_file_path)

    # Vérifie que le fichier SQL existe, sinon retourne un DataFrame avec message d'erreur
    if not sql_file.is_file():
        print(f"Fichier SQL introuvable : {sql_file_path}")
        return pd.DataFrame({"info_message": [f"Fichier SQL introuvable : {sql_file_path}"]})

    # Construction de l'URL de connexion PostgreSQL compatible SQLAlchemy
    connection_url = (
        f"postgresql+psycopg2://{db_conf['user']}:{db_conf['password']}"
        f"@{db_conf['host']}:{db_conf['port']}/{db_name}"
    )
    try:
        # Création de l'objet engine SQLAlchemy avec autocommit pour exécuter DDL si nécessaire
        engine = create_engine(connection_url, isolation_level="AUTOCOMMIT")

        # Lecture du contenu du fichier SQL
        sql_text = sql_file.read_text(encoding="utf-8")

        # Ouverture d'une connexion à la base de données
        with engine.connect() as conn:
            # Exécution de la requête SQL
            result = conn.execute(text(sql_text))
            
            # Si la requête renvoie des lignes (ex: SELECT), créer un DataFrame
            if result.returns_rows:
                df = pd.DataFrame(result.fetchall(), columns=result.keys())
            else:
                # Si la requête ne renvoie rien (ex: CREATE TABLE), renvoyer un message
                df = pd.DataFrame({"info_message": ["Requête exécutée avec succès, pas de résultat à afficher."]})
            
            return df

    except SQLAlchemyError as e:
        # Capture des erreurs SQLAlchemy et retour d'un DataFrame contenant l'erreur
        return pd.DataFrame({"info_message": [f"Erreur lors de l'exécution : {e}"]})

    finally:
        # Libération des ressources de l'engine pour fermer proprement la connexion
        if 'engine' in locals():
            engine.dispose()


## Exemple

df = execute_sql_to_df(db_conf, db_conf["db_accm"], SQL_FILES_PATH/sql_file_conf["file_1"])
df.head()