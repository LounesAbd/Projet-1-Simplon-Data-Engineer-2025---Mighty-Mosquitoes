# Projet-1-Simplon-Data-Engineer-2025---Mighty-Mosquitoes
ETL et analyse de donnée sur le dataset "Accidents corporels de la circulation millésimé".



## Utilisation des fichiers .env et config.yaml

Le fichier .env stocke les informations sensibles (mots de passe, clés d’API, identifiants de base de données) et n’est pas versionné.

Fichier .env
```
POSTGRES_USER=postgres
POSTGRES_PASSWORD=secret123
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=ma_base
```
Le fichier config.yaml contient les paramètres non sensibles (noms de tables, chemins, options de nettoyage) et peut être versionné.

config.yml
```
database:
  user: ${POSTGRES_USER}
  password: ${POSTGRES_PASSWORD}
  host: ${POSTGRES_HOST}
  port: ${POSTGRES_PORT}
  db: ${POSTGRES_DB}
```
Cette séparation garantit un projet sécurisé, portable et facile à maintenir.
