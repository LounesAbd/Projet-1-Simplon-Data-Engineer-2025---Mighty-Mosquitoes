#!/usr/bin/env python3
"""
Script de téléchargement du dataset complet 'Accidents corporels de la circulation millésimé'
depuis l'API OpenDataSoft.

Le dataset couvre les années 2012-2019 et contient toutes les informations sur les accidents
corporels de la circulation en France.

Usage:
    python sauvegarde_csv_api.py [--output OUTPUT_PATH] [--delimiter DELIMITER]
                                 [--limit N] [--where FILTER]

Arguments:
    --output OUTPUT_PATH    Chemin du fichier de sortie (défaut: data/accidents_corporels_millesime.csv)
    --delimiter DELIMITER   Séparateur CSV (défaut: ,)
    --no-progress           Désactiver la barre de progression
    --retry RETRY           Nombre de tentatives en cas d'erreur (défaut: 3)
    --limit N               Limite le nombre d'enregistrements renvoyés par l'API
    --where FILTER          Expression de filtrage (syntaxe OpenDataSoft)

Exemples:
    # Téléchargement standard
    python sauvegarde_csv_api.py

    # Téléchargement avec chemin personnalisé
    python sauvegarde_csv_api.py --output /tmp/accidents.csv

    # Téléchargement limité avec un filtre
    python sauvegarde_csv_api.py --delimiter "," --limit 1000 --where "an=2023"
"""

import argparse
import csv
import sys
import time
from urllib.parse import urlencode
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Callable, Optional, Tuple


try:
    import requests
except ImportError:
    print("❌ Erreur: Le module 'requests' n'est pas installé.")
    print("   Installez-le avec: pip install requests")
    sys.exit(1)

try:
    from tqdm import tqdm
    HAS_TQDM = True
except ImportError:
    HAS_TQDM = False

@dataclass(frozen=True)
class DownloadConfig:
    """Paramètres pour le téléchargement du dataset."""

    base_url: str = "https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets"
    dataset_id: str = "accidents-corporels-de-la-circulation-millesime"
    output_dir: str = "data"
    output_file: str = "accidents_corporels_millesime.csv"
    delimiter: str = ","
    retries: int = 3
    chunk_size: int = 65536
    timeout: int = 30
    progress: bool = True
    limit: Optional[int] = None
    where: Optional[str] = None


@dataclass
class CsvStats:
    """Statistiques de base sur le CSV téléchargé."""

    exists: bool = False
    size_bytes: int = 0
    line_count: int = 0
    header: Tuple[str, ...] = ()

    @property
    def is_valid(self) -> bool:
        return self.exists and bool(self.header)

    @property
    def column_count(self) -> int:
        return len(self.header)

    @property
    def size_mb(self) -> float:
        if not self.size_bytes:
            return 0.0
        return self.size_bytes / (1024 * 1024)

    @property
    def record_count(self) -> int:
        if self.line_count <= 1:
            return 0
        return self.line_count - 1


DEFAULT_CONFIG = DownloadConfig()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Télécharge le dataset complet des accidents corporels de la circulation (2012-2019) depuis OpenDataSoft.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemples:
  %(prog)s
  %(prog)s --output /tmp/accidents.csv
  %(prog)s --delimiter "," --limit 1000
  %(prog)s --where "an=2022" --no-progress
        """,
    )

    parser.add_argument(
        "--output",
        type=str,
        help="Chemin du fichier de sortie (défaut: data/accidents_corporels_millesime.csv)",
    )
    parser.add_argument(
        "--delimiter",
        type=str,
        default=DEFAULT_CONFIG.delimiter,
        help=f"Délimiteur CSV (défaut: {DEFAULT_CONFIG.delimiter})",
    )
    parser.add_argument(
        "--no-progress",
        action="store_true",
        help="Désactiver la barre de progression",
    )
    parser.add_argument(
        "--retry",
        type=int,
        default=DEFAULT_CONFIG.retries,
        help=f"Nombre de tentatives en cas d'erreur (défaut: {DEFAULT_CONFIG.retries})",
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="Nombre maximum de lignes à télécharger (optionnel)",
    )
    parser.add_argument(
        "--where",
        type=str,
        help="Expression de filtrage (syntaxe OpenDataSoft, optionnel)",
    )
    
    return parser.parse_args()


def resolve_output_path(config: DownloadConfig, override: Optional[str]) -> Path:
    """Détermine le chemin final du fichier de sortie."""

    if override:
        return Path(override).expanduser()

    script_dir = Path(__file__).resolve().parent.parent
    return script_dir / config.output_dir / config.output_file


def build_download_url(config: DownloadConfig) -> str:
    """Construit l'URL de téléchargement pour la configuration donnée."""

    params = {"delimiter": config.delimiter}
    if config.limit is not None:
        params["limit"] = config.limit
    if config.where:
        params["where"] = config.where
        
    query = urlencode(params, doseq=True)
    return f"{config.base_url}/{config.dataset_id}/exports/csv?{query}"


def make_progress_handler(enabled: bool, total_bytes: Optional[int]) -> Tuple[Callable[[int], None], Callable[[], None]]:
    """Crée les fonctions d'update et de fermeture de la progression."""

    if not enabled:
        return (lambda _: None, lambda: None)

    if HAS_TQDM:
        bar = tqdm(
            total=total_bytes,
            unit="B",
            unit_scale=True,
            unit_divisor=1024,
            desc="Téléchargement",
        )
        return bar.update, bar.close

    state = {"downloaded": 0}

    def update(amount: int) -> None:
        state["downloaded"] += amount
        if total_bytes:
            percent = (state["downloaded"] / total_bytes) * 100
            print(f"\r   Progression: {percent:5.1f}%", end="", flush=True)
            return
        kilobytes = state["downloaded"] / 1024
        print(f"\r   Téléchargé: {kilobytes:,.1f} KB", end="", flush=True)

    def close() -> None:
        if state["downloaded"]:
            print()

    return update, close


def download_once(url: str, destination: Path, config: DownloadConfig, show_progress: bool) -> None:
    """Télécharge le fichier une fois, sans logique de retry."""

    print("🌐 Connexion à OpenDataSoft...")
    response = requests.get(url, stream=True, timeout=config.timeout)
    response.raise_for_status()

    content_length = response.headers.get("content-length")
    try:
        total_bytes = int(content_length) if content_length else None
    except (TypeError, ValueError):
        total_bytes = None

    if total_bytes:
        size_mb = total_bytes / (1024 * 1024)
        print(f"📥 Téléchargement (~{size_mb:.2f} MB)")
    else:
        print("📥 Téléchargement (taille inconnue)")

    update_progress, close_progress = make_progress_handler(show_progress, total_bytes)

    destination.parent.mkdir(parents=True, exist_ok=True)
    with response, open(destination, "wb") as handle:
        for chunk in response.iter_content(chunk_size=config.chunk_size):
            if not chunk:
                continue
            handle.write(chunk)
            update_progress(len(chunk))

    close_progress()
    print(f"✅ Fichier sauvegardé: {destination}")


def download_with_retries(url: str, destination: Path, config: DownloadConfig, show_progress: bool) -> None:
    """Gère les tentatives multiples de téléchargement avec backoff exponentiel."""

    for attempt in range(1, config.retries + 1):
        try:
            download_once(url, destination, config, show_progress)
            return
        except requests.RequestException as error:
            print(f"❌ Erreur lors du téléchargement (tentative {attempt}/{config.retries}): {error}")
            if attempt == config.retries:
                raise
            wait_time = 2 ** attempt
            print(f"⏳ Nouvelle tentative dans {wait_time} secondes...")
            time.sleep(wait_time)


def collect_csv_stats(file_path: Path, delimiter: str) -> CsvStats:
    """Lit le fichier CSV et retourne des statistiques de validation."""

    if not file_path.exists():
        return CsvStats()

    size_bytes = file_path.stat().st_size

    try:
        with file_path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.reader(handle, delimiter=delimiter)
            header = tuple(next(reader, ()))
            if not header:
                return CsvStats(exists=True, size_bytes=size_bytes)

            line_count = 1
            for _ in reader:
                line_count += 1
    except Exception as error:
        print(f"❌ Erreur lors de la lecture du CSV: {error}")
        return CsvStats(exists=True, size_bytes=size_bytes)
    
    return CsvStats(exists=True, size_bytes=size_bytes, line_count=line_count, header=header)


def print_run_header(output_path: Path, config: DownloadConfig) -> None:
    """Affiche l'entête de session de téléchargement."""

    separator = "=" * 60
    print(f"\n{separator}")
    print("🚗 TÉLÉCHARGEMENT DATASET ACCIDENTS CORPORELS")
    print(separator)
    print("📍 Source: OpenDataSoft")
    print("📅 Période: 2012-2019")
    print(f"📄 Fichier: {output_path}")
    print(f"🔤 Séparateur: '{config.delimiter}'")
    if config.limit is not None:
        print(f"🔢 Limite: {config.limit}")
    if config.where:
        print(f"🔍 Filtre: {config.where}")
    print(f"{separator}\n")


def print_summary(stats: CsvStats) -> None:
    """Affiche un résumé des statistiques du téléchargement."""

    separator = "=" * 60
    print(f"\n{separator}")
    print("📊 RÉSUMÉ DU TÉLÉCHARGEMENT")
    print(separator)

    if not stats.is_valid:
        print("❌ Fichier invalide ou incomplet")
        if stats.size_bytes:
            print(f"   Taille: {stats.size_mb:.2f} MB")
        print(f"{separator}\n")
        return

    print("✅ Fichier valide")
    print(f"   Taille: {stats.size_mb:.2f} MB ({stats.size_bytes:,} bytes)")
    print(f"   Lignes: {stats.line_count:,} (incluant l'en-tête)")
    print(f"   Records: {stats.record_count:,} accidents")
    print(f"   Colonnes: {stats.column_count}")

    if stats.header:
        print("\n📋 Premières colonnes:")
        preview = stats.header[:10]
        for index, name in enumerate(preview, start=1):
            print(f"   {index}. {name}")
        remaining = stats.column_count - len(preview)
        if remaining > 0:
            print(f"   ... et {remaining} autres colonnes")

    print(f"{separator}\n")


def download_accidents(
    output: Optional[str] = None,
    delimiter: str = ",",
    show_progress: bool = True,
    retries: int = 3,
    limit: Optional[int] = None,
    where: Optional[str] = None,    
) -> CsvStats:
    """
    Télécharge le dataset des accidents corporels depuis OpenDataSoft.

    Args:
        output: Chemin du fichier de sortie (optionnel, utilise data/accidents_corporels_millesime.csv par défaut)
        delimiter: Séparateur CSV (défaut: ',')
        show_progress: Afficher la barre de progression (défaut: True)
        retries: Nombre de tentatives en cas d'erreur (défaut: 3)
        limit: Nombre maximum de lignes à télécharger (optionnel)
        where: Expression de filtrage OpenDataSoft (optionnel)
        
    Returns:
        CsvStats: Statistiques sur le fichier téléchargé

    Raises:
        requests.RequestException: En cas d'échec du téléchargement après toutes les tentatives
    """
    config = replace(
        DEFAULT_CONFIG,
        delimiter=delimiter,
        retries=retries,
        limit=limit,
        where=where,
    )
    output_path = resolve_output_path(config, output)

    print_run_header(output_path, config)

    if not HAS_TQDM and show_progress:
        print("⚠️  Module 'tqdm' non installé - pas de barre de progression détaillée")
        print("   Installez-le avec: pip install tqdm\n")

    url = build_download_url(config)

    start_time = time.time()
    download_with_retries(url, output_path, config, show_progress)

    elapsed_time = time.time() - start_time
    print(f"⏱️  Temps de téléchargement: {elapsed_time:.1f} secondes")

    #stats = collect_csv_stats(output_path, config.delimiter)
    #print_summary(stats)

    return #stats


def main() -> None:
    args = parse_args()

    output = args.output
    delimiter = args.delimiter
    show_progress = not args.no_progress
    retries = args.retry
    limit = args.limit
    where = args.where
    
    try:
        stats = download_accidents(output, delimiter, show_progress, retries, limit, where)
    except requests.RequestException as error:
        print(f"❌ Échec du téléchargement: {error}")
        sys.exit(1)

    if not stats.is_valid:
        print("❌ Le fichier téléchargé semble invalide.")
        sys.exit(1)

    print("✅ Téléchargement et validation réussis !")
    sys.exit(0)


if __name__ == "__main__":
    main()
