from rdflib import URIRef
import uuid
import json
import os
from pathlib import Path

LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()
MU_SPARQL_ENDPOINT = os.environ.get("MU_SPARQL_ENDPOINT", "http://database:8890/sparql")
MU_SPARQL_UPDATEPOINT = os.environ.get("MU_SPARQL_UPDATEPOINT", MU_SPARQL_ENDPOINT)

TMP_GRAPH         = "http://mu.semte.ch/graphs/tmp-export"
PUBLIC_GRAPH      = "http://mu.semte.ch/graphs/public"
BATCH_SIZE        = 500
INSERT_BATCH_SIZE = 100000
CONCURRENCY       = 4

CONFIG_DIR        = Path(__file__).parent / "./"
CONFIG_FILE       = CONFIG_DIR / "config.json"
# scripts/project/config.json mounts $PWD (the repo root mu-cli is run from) at
# /data/app/ — not /app — so this lands in ./data/datadumps on the host, served
# by the `datadumps` nginx container.
OUTPUT_DIR        = Path(os.environ.get("OUTPUT_DIR", "/data/app/data/datadumps"))
BASE_URL          = os.environ.get("BASE_URL", "http://data.lblod.info") 

SHAPES_BASE_URL   = "https://shacl-play.sparna.fr/shapes/"

def get_datasets() -> dict:
    if not CONFIG_FILE.exists():
        sys.exit(f"[Error] config file not found: {CONFIG_FILE}")

    with open(CONFIG_FILE, encoding="utf-8") as fh:
        datasets = json.load(fh)["datasets"]

    for name, dataset in datasets.items():
        sparql_file = CONFIG_DIR / dataset["sparql_file"]
        if not sparql_file.exists():
            sys.exit(f"[Error] sparql file for dataset '{name}' not found: {sparql_file}")
        dataset["insert_query"] = sparql_file.read_text(encoding="utf-8")

    return datasets

def get_organizations() -> dict:
    if not CONFIG_FILE.exists():
        sys.exit(f"[Error] config file not found: {CONFIG_FILE}")

    with open(CONFIG_FILE, encoding="utf-8") as fh:
        organizations = json.load(fh)["catalogs"]

    for name, org in organizations.items():
        for field in ("catalog_uri", "catalog_uuid", "catalog_publisher", "organizationFilter"):
            if field not in org:
                sys.exit(f"[Error] Organization '{name}' is missing required field '{field}' in {CONFIG_FILE}")

    return organizations

def shacl_file_name(output_file_name: str, timestamp: str) -> str:
    return f"{timestamp}-{output_file_name}-shacl.ttl"

def shacl_adapted_file_name(output_file_name: str, timestamp: str) -> str:
    return f"{timestamp}-{output_file_name}-shacl-adapted.ttl"

def datadump_file_name(output_file_name: str, timestamp: str) -> str:
    return f"{timestamp}-{output_file_name}.ttl"

def landing_page_file_name(output_file_name: str, timestamp: str) -> str:
    return f"{timestamp}-{output_file_name}.html"

def dataset_uri_and_uuid(
    dataset: str, dataset_config: dict, organization: str, organization_config: dict,
) -> tuple[str, URIRef]:
    # Dataset UUID changes when its configuration changes or organizationFilter
    dataset_uuid = str(uuid.uuid5(
        uuid.NAMESPACE_URL,
        f"{organization}/{dataset}/dataset/{json.dumps(dataset_config, sort_keys=True)}/{organization_config.get('organizationFilter', '')}",
    ))
    return dataset_uuid, URIRef(f"http://data.lblod.info/id/datasets/{dataset_uuid}")

def service_uri_and_uuid(dataset: str, dataset_config: dict, organization: str) -> tuple[str, URIRef]:
    # Data service UUID changes when the sparql endpoint changes
    service_uuid = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{organization}/{dataset}/service/{dataset_config.get('sparql_endpoint', '')}"))
    return service_uuid, URIRef(f"http://data.lblod.info/id/services/{service_uuid}")

def distribution_uri_and_uuid(
    dataset: str, dataset_config: dict, organization: str, timestamp: str) -> tuple[str, URIRef]:
    # Distribution UUID changes with each run, as a timestamp is added to the datadump
    distribution_uuid = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{organization}/{dataset}/distribution/{timestamp}"))
    return distribution_uuid, URIRef(f"http://data.lblod.info/id/distributions/{distribution_uuid}")