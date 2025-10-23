"""
SQL Query Loader pour Mighty Mosquitoes

Parse et charge les requêtes SQL depuis les fichiers sources dans etl/sql/
Permet d'éliminer la duplication de code en faisant des fichiers SQL
la source unique de vérité.

Usage:
    loader = SQLQueryLoader()
    query = loader.load_query('section1', '1.1')
    df = pd.read_sql(query, engine)
"""

import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple


class QueryNotFoundError(Exception):
    """Exception levée quand une requête n'est pas trouvée."""
    pass


class SQLQueryLoader:
    """Parse et charge les requêtes SQL depuis les fichiers sources."""

    # Pattern pour identifier les marqueurs de requêtes
    # Exemples :
    # -- 1.1 KPI PRIORITAIRE : Description
    # -- 2.3 KPI SECONDAIRE : Description
    # -- 6.1 Analyse hebdomadaire avec z-score
    # -- 1.5.1 Par régime de circulation
    QUERY_MARKER_PATTERN = re.compile(
        r'^--\s+(\d+\.\d+(?:\.\d+)?)\s+(?:KPI\s+(PRIORITAIRE|SECONDAIRE)\s*:\s*)?(.+)$',
        re.IGNORECASE
    )

    # Pattern pour les lignes de séparation (à ignorer)
    SEPARATOR_PATTERN = re.compile(r'^--\s*[-=]{3,}\s*$')

    def __init__(self, sql_dir: str = 'sql'):
        """
        Initialise le loader.

        Args:
            sql_dir: Chemin vers le dossier contenant les fichiers SQL
                    (relatif depuis notebooks/ par défaut)
        """
        self.sql_dir =  Path(__file__).parent / sql_dir
        if not self.sql_dir.exists():
            raise FileNotFoundError(
                f"Le dossier SQL n'existe pas : {self.sql_dir.absolute()}"
            )

        # Cache pour éviter de re-parser les fichiers
        self._cache: Dict[str, Dict[str, Dict]] = {}

    def _get_section_file(self, section: str) -> Path:
        """
        Retourne le chemin du fichier pour une section donnée.

        Args:
            section: 'section1', 'section2', etc.

        Returns:
            Path vers le fichier SQL

        Raises:
            FileNotFoundError: Si le fichier n'existe pas
        """
        # Mapping section → fichier
        section_files = {
            'section1': 'section1_kpi_zones.sql',
            'section2': 'section2_kpi_conditions.sql',
            'section3': 'section3_kpi_tendances.sql',
            'section4': 'section4_conditions_risque.sql',
            'section5': 'section5_flux_graves.sql',
            'section6': 'section6_anomalies_temporelles.sql',
        }

        if section not in section_files:
            raise ValueError(
                f"Section inconnue : {section}. "
                f"Sections disponibles : {', '.join(section_files.keys())}"
            )

        file_path = self.sql_dir / section_files[section]
        if not file_path.exists():
            raise FileNotFoundError(
                f"Fichier SQL introuvable : {file_path.absolute()}"
            )

        return file_path

    def _parse_section_file(self, section: str) -> Dict[str, Dict]:
        """
        Parse un fichier de section et extrait toutes les requêtes.

        Args:
            section: 'section1', 'section2', etc.

        Returns:
            Dict[query_id, metadata] où metadata contient :
                - id: '1.1', '1.5.1', etc.
                - priority: 'PRIORITAIRE', 'SECONDAIRE', ou None
                - description: Description de la requête
                - line_start: Numéro de ligne de début
                - line_end: Numéro de ligne de fin
                - query: La requête SQL complète
        """
        # Vérifier le cache
        if section in self._cache:
            return self._cache[section]

        file_path = self._get_section_file(section)
        queries = {}

        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        current_query_id = None
        current_priority = None
        current_description = None
        current_start_line = None
        current_sql_lines = []

        for line_num, line in enumerate(lines, start=1):
            # Vérifier si c'est un marqueur de requête
            match = self.QUERY_MARKER_PATTERN.match(line)

            if match:
                # Sauvegarder la requête précédente si elle existe
                if current_query_id is not None:
                    queries[current_query_id] = {
                        'id': current_query_id,
                        'priority': current_priority,
                        'description': current_description,
                        'line_start': current_start_line,
                        'line_end': line_num - 1,
                        'query': self._clean_query(''.join(current_sql_lines)),
                        'file_path': str(file_path.relative_to(self.sql_dir.parent))
                    }

                # Démarrer une nouvelle requête
                current_query_id = match.group(1)
                current_priority = match.group(2)  # Peut être None
                current_description = match.group(3).strip()
                current_start_line = line_num
                current_sql_lines = []

            # Ignorer les lignes de séparation
            elif self.SEPARATOR_PATTERN.match(line):
                continue

            # Si on est dans une requête, accumuler les lignes SQL
            elif current_query_id is not None:
                # Ignorer les commentaires de titre de section
                if line.strip().startswith('-- SECTION'):
                    continue
                if line.strip().startswith('-- ==='):
                    continue

                current_sql_lines.append(line)

        # Sauvegarder la dernière requête
        if current_query_id is not None:
            queries[current_query_id] = {
                'id': current_query_id,
                'priority': current_priority,
                'description': current_description,
                'line_start': current_start_line,
                'line_end': len(lines),
                'query': self._clean_query(''.join(current_sql_lines)),
                'file_path': str(file_path.relative_to(self.sql_dir.parent))
            }

        # Mettre en cache
        self._cache[section] = queries
        return queries

    def _clean_query(self, sql: str) -> str:
        """
        Nettoie une requête SQL extraite.

        - Supprime les lignes vides au début et à la fin
        - Préserve l'indentation et les commentaires internes

        Args:
            sql: Requête SQL brute

        Returns:
            Requête nettoyée
        """
        lines = sql.split('\n')

        # Supprimer les lignes vides au début
        while lines and not lines[0].strip():
            lines.pop(0)

        # Supprimer les lignes vides à la fin
        while lines and not lines[-1].strip():
            lines.pop()

        return '\n'.join(lines)

    def load_query(self, section: str, query_id: str) -> str:
        """
        Charge une requête SQL spécifique.

        Args:
            section: 'section1', 'section2', etc.
            query_id: '1.1', '1.5.1', '2.3', etc.

        Returns:
            La requête SQL complète (str)

        Raises:
            QueryNotFoundError: Si la requête n'existe pas

        Example:
            >>> loader = SQLQueryLoader()
            >>> query = loader.load_query('section1', '1.1')
            >>> print(query[:50])
            WITH stats AS (
                SELECT
                    reg_code,
        """
        queries = self._parse_section_file(section)

        if query_id not in queries:
            available = ', '.join(sorted(queries.keys()))
            raise QueryNotFoundError(
                f"Requête {query_id} introuvable dans {section}. "
                f"Requêtes disponibles : {available}"
            )

        return queries[query_id]['query']
   
    def clear_cache(self):
        """Vide le cache des requêtes parsées."""
        self._cache.clear()