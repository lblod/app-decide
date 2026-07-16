#!/usr/bin/env python3
import argparse
import json
import math
import time
import sys
import os
import uuid
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from jinja2 import Environment, FileSystemLoader
from rdflib import BNode, Literal, URIRef
from rdflib import Graph as RDFGraph
from helpers import query, update, log
env = Environment(loader=FileSystemLoader("."))

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

def load_datasets() -> dict:
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

def load_organizations() -> dict:
    if not CONFIG_FILE.exists():
        sys.exit(f"[Error] config file not found: {CONFIG_FILE}")

    with open(CONFIG_FILE, encoding="utf-8") as fh:
        organizations = json.load(fh)["catalogs"]

    for name, org in organizations.items():
        for field in ("catalog_uri", "catalog_uuid", "catalog_publisher", "organizationFilter"):
            if field not in org:
                sys.exit(f"[Error] Organization '{name}' is missing required field '{field}' in {CONFIG_FILE}")

    return organizations

def select_rows(q: str) -> list[dict]:
    bindings = query(q)["results"]["bindings"]
    return [{k: v["value"] for k, v in row.items()} for row in bindings]


def graph_has_subject(subject: str, graph: str) -> bool:
    return query(f"ASK {{ GRAPH <{graph}> {{ <{subject}> ?p ?o . }} }}")["boolean"]


def get_issued(subject: str, graph: str) -> str | None:
    """Return `subject`'s existing dct:issued value, if any, so a re-render can preserve it instead of resetting it."""
    rows = select_rows(f"""
PREFIX dct: <http://purl.org/dc/terms/>
SELECT ?issued WHERE {{ GRAPH <{graph}> {{ <{subject}> dct:issued ?issued . }} }}
""")
    return rows[0]["issued"] if rows else None


def delete_subjects(subjects: list[str], graph: str) -> None:
    """Delete every triple whose subject is one of `subjects`, so a re-render can fully replace them."""
    values = " ".join(f"<{s}>" for s in subjects)
    update(f"""
DELETE {{
  GRAPH <{graph}> {{ ?subject ?p ?o . }}
}}
WHERE {{
  GRAPH <{graph}> {{ ?subject ?p ?o . }}
  VALUES ?subject {{ {values} }}
}}
""")


def turtle_to_insert_data(turtle: str, graph: str) -> str:
    """Parse rendered Turtle and serialize to N-Triples so it can be embedded
    in a SPARQL INSERT DATA block without dealing with prefix declarations."""
    g = RDFGraph()
    g.parse(data=turtle, format="turtle")
    ntriples = g.serialize(format="nt")
    return f"INSERT DATA {{ GRAPH <{graph}> {{\n{ntriples}\n}} }}"


def _insert_to_count(insert_query: str, interesting_variable: str) -> str:
    upper      = insert_query.upper()
    insert_pos = upper.index("INSERT")
    where_pos  = upper.index("WHERE", insert_pos)
    prefixes   = insert_query[:insert_pos]
    where_body = insert_query[where_pos:].rstrip()
    assert where_body.endswith("}"), "WHERE clause must end with }"
    return prefixes + f"SELECT (COUNT(DISTINCT ?{interesting_variable}) AS ?n) " + where_body + "\n"


def _paginate_insert(insert_query: str, limit: int, offset: int) -> str:
    # SPARQL Update has no solution modifier on INSERT ... WHERE itself (that's
    # a Virtuoso-only extension); a standard-compliant proxy like sparql-parser
    # rejects trailing LIMIT/OFFSET there. Instead, wrap the WHERE body in a
    # `{ SELECT * WHERE { ... } LIMIT n OFFSET m }` subquery, which is valid
    # SPARQL 1.1 and projects every variable bound inside.
    body = insert_query.rstrip()
    assert body.endswith("}"), "INSERT query must end with the closing WHERE brace }"
    upper = body.upper()
    where_pos = upper.index("WHERE")
    head = body[:where_pos]
    open_brace_pos = body.index("{", where_pos)
    where_inner = body[open_brace_pos + 1:-1]
    return f"{head}WHERE {{\n  SELECT * WHERE {{\n{where_inner}\n  }}\n  LIMIT {limit}\n  OFFSET {offset}\n}}\n"


def step1_populate_tmp_graph(insert_query: str, interesting_variables: list[str]) -> None:
    log("[Step 1] Counting distinct subjects (?%s) …", "  ?".join(interesting_variables))
    total_count = 0
    for var in interesting_variables:
        rows = select_rows(_insert_to_count(insert_query, var))
        n = int(rows[0]["n"]) if rows else 0
        log("  [Step 1] ?%s: %d distinct", var, n)
        total_count += n

    if total_count == 0:
        log("[Step 1] Nothing to queue.")
        return

    num_batches = math.ceil(total_count / INSERT_BATCH_SIZE)
    log("[Step 1] %d distinct subject URIs → %d batch(es) of %d (%d parallel)",
        total_count, num_batches, INSERT_BATCH_SIZE, CONCURRENCY)

    completed = 0
    with ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
        futures = {
            executor.submit(update, _paginate_insert(insert_query, INSERT_BATCH_SIZE, i * INSERT_BATCH_SIZE)): i + 1
            for i in range(num_batches)
        }
        for future in as_completed(futures):
            future.result()
            completed += 1
            log("  [Step 1] %d/%d batches done", completed, num_batches)

    log("[Step 1] Done. %d distinct subject URIs queued.", total_count)


def step2_fetch_batch() -> list[str]:
    q = f"""
SELECT DISTINCT ?subject WHERE {{
  GRAPH <{TMP_GRAPH}> {{
    ?subject ?p ?o .
  }}
}} LIMIT {BATCH_SIZE}
"""
    return [row["subject"] for row in select_rows(q)]


def _term_from_binding(binding: dict):
    value = binding["value"]
    if binding["type"] == "uri":
        return URIRef(value)
    if binding["type"] == "bnode":
        return BNode(value)
    lang = binding.get("xml:lang")
    if lang:
        return Literal(value, lang=lang)
    datatype = binding.get("datatype")
    if datatype:
        return Literal(value, datatype=URIRef(datatype))
    return Literal(value)


def step3_construct_batch(subjects: list[str]) -> str:
    # The sparql-parser service always returns sparql-results+json regardless
    # of the requested Accept header; for CONSTRUCT it represents each produced
    # triple as a binding row named after the template's variables (?s/?p/?o)
    # rather than RDF, so build the Turtle client-side from those bindings.
    values = " ".join(f"<{s}>" for s in subjects)
    q = f"""
CONSTRUCT {{ ?s ?p ?o }} WHERE {{
  VALUES ?s {{ {values} }}
  ?s ?p ?o .
  FILTER NOT EXISTS {{
    GRAPH <{TMP_GRAPH}> {{ ?s ?p ?o . }}
  }}
}}
"""
    bindings = query(q)["results"]["bindings"]
    g = RDFGraph()
    for row in bindings:
        g.add((URIRef(row["s"]["value"]), URIRef(row["p"]["value"]), _term_from_binding(row["o"])))
    return g.serialize(format="turtle")


def step4_delete_batch(subjects: list[str]) -> None:
    values = " ".join(f"<{s}>" for s in subjects)
    q = f"""
DELETE {{
  GRAPH <{TMP_GRAPH}> {{ ?subject ?p ?o . }}
}}
WHERE {{
  GRAPH <{TMP_GRAPH}> {{ ?subject ?p ?o . }}
  VALUES ?subject {{ {values} }}
}}
"""
    update(q)

def datadump_file_name(output_file_name: str, timestamp: str) -> str:
    return f"{timestamp}-{output_file_name}.ttl"


def run_datadump_pipeline(timestamp: str, dataset: str, dataset_config: dict, organization_config: dict) -> None:
    log("=== Dataset: %s ===", dataset_config['description'])
    output_file_name = dataset_config.get("output_file_name", dataset)

    insert_query = env.from_string(dataset_config["insert_query"]).render(
        organizationFilter=organization_config.get("organizationFilter", ""))

    step1_populate_tmp_graph(insert_query, dataset_config["interesting_variables"])

    total = 0
    output_file = OUTPUT_DIR / datadump_file_name(output_file_name, timestamp)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as fh:
        while True:
            batch = step2_fetch_batch()
            if not batch:
                log("[Pipeline] Tmp graph is empty – extraction complete.")
                break

            turtle = step3_construct_batch(batch)
            fh.write(turtle)
            fh.write("\n")

            step4_delete_batch(batch)

            total += len(batch)
            log("[Pipeline] Processed %d subjects …", total)
            time.sleep(0.1)

    log("[Pipeline] Finished. %d subjects written to '%s'.", total, output_file)

def step1_write_catalog(organization: str, organization_config: dict, now_iso: str) -> None:
    log("[Step 1] Generate DCAT Catalog for %s", organization)
    catalog_uri = organization_config["catalog_uri"]
    catalog_publisher_uri = organization_config["catalog_publisher"].get("uri")
    catalog_subjects = [catalog_uri] + ([catalog_publisher_uri] if catalog_publisher_uri else [])

    if graph_has_subject(catalog_uri, PUBLIC_GRAPH):
        log("Catalog '%s' already exists in <%s>, doing nothing.", organization, PUBLIC_GRAPH)
    else:
        catalog_template = env.get_template("templates/dcat-catalog.ttl.j2")
        catalog_output = catalog_template.render(
            ISSUED=now_iso,
            MODIFIED=now_iso,
            **organization_config)
        update(turtle_to_insert_data(catalog_output, PUBLIC_GRAPH))
        log("DCAT Catalog '%s' written to <%s>.", organization, PUBLIC_GRAPH)


def step2_write_dataset(organization: str, organization_config: dict, dataset: str, dataset_config: dict, timestamp: str, timestamp_iso: str) -> None:
    log("[Step 2] Generate DCAT Dataset for %s", dataset_config['description'])
    # Dataset UUID changes when its configuration changes or organizationFilter
    dataset_uuid = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{organization}/{dataset}/dataset/{json.dumps(dataset_config, sort_keys=True)}/{organization_config.get('organizationFilter', '')}"))
    # Data service UUID changes when the sparql endpoint changes
    service_uuid = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{organization}/{dataset}/service/{dataset_config.get('sparql_endpoint', '')}"))
    # Distribution UUID changes with each run, as a timestamp is added to the datadump
    distribution_uuid = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{organization}/{dataset}/distribution/{timestamp}"))
    dataset_uri = f"http://data.lblod.info/id/datasets/{dataset_uuid}"
    service_uri = f"http://data.lblod.info/id/services/{service_uuid}"
    distribution_uri = f"http://data.lblod.info/id/distributions/{distribution_uuid}"

    insert_dataset = True
    insert_dataservice = True
    insert_distribution = True
    if graph_has_subject(dataset_uri, PUBLIC_GRAPH):
        log("DCAT Dataset '%s' already exists in <%s>, only appending link to the service and distribution if they don't exist yet.", dataset, PUBLIC_GRAPH)
        insert_dataset = False
        if graph_has_subject(service_uri, PUBLIC_GRAPH):
            insert_dataservice = False
        if graph_has_subject(distribution_uri, PUBLIC_GRAPH):
            insert_distribution = False

    datadump_base_url = organization_config.get("datadump_base_url")
    output_file_name = dataset_config.get("output_file_name", dataset)
    datadump_url = (
        f"{datadump_base_url.rstrip('/')}/{datadump_file_name(output_file_name, timestamp)}"
        if datadump_base_url else None
    )
    dataset_template = env.get_template("templates/dcat-dataset.ttl.j2")
    dataset_output = dataset_template.render(
        insert_dataset=insert_dataset,
        insert_dataservice=insert_dataservice,
        insert_distribution=insert_distribution,
        ISSUED=timestamp_iso,
        MODIFIED=timestamp_iso,
        dataset=dataset_config,
        dataset_uri=dataset_uri,
        dataset_uuid=dataset_uuid,
        service_uri=service_uri,
        service_uuid=service_uuid,
        distribution_uri=distribution_uri,
        distribution_uuid=distribution_uuid,
        datadump_url=datadump_url,
        **organization_config)
    update(turtle_to_insert_data(dataset_output, PUBLIC_GRAPH))
    log("DCAT Dataset '%s' written to <%s>.", dataset, PUBLIC_GRAPH)

def generate_dcat(timestamp: str, dataset: str, dataset_config: dict, organization: str, organization_config: dict) -> None:
    if not organization_config.get("sparql_endpoint"):
        log("  No 'sparql_endpoint' configured for organization '%s', skipping its SPARQL DCAT service.", organization)
    if not organization_config.get("datadump_base_url"):
        log("  No 'datadump_base_url' configured for organization '%s', skipping its data dump distribution.", organization)

    timestamp_iso = datetime.strptime(timestamp, "%Y%m%d%H%M%S").isoformat()

    log("=== Generating DCAT ===")
    log("Processing for '%s' …", organization)

    step1_write_catalog(organization, organization_config, timestamp_iso)
    step2_write_dataset(organization, organization_config, dataset, dataset_config, timestamp, timestamp_iso)

    log("[Pipeline] Finished. DCAT catalog + dataset written for dataset '%s' (organization: '%s') to <%s>.", dataset, organization, PUBLIC_GRAPH)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate a datadump (.ttl) for a configured dataset of an organization and write DCAT metadata to the triple store for discovery.",
        epilog="Example: mu script project-scripts publish-dataset --dataset codelists --org gent",
    )
    parser.add_argument("--dataset",  help="Dataset to process")
    parser.add_argument("--org", help="Organization to download datasets for")
    parser.add_argument("--list", action="store_true", help="List available datasets and organizations")
    parser.add_argument("--skip-dcat", action="store_true", help="Only generate the datadump; skip writing DCAT metadata to the triple store")
    args = parser.parse_args()

    if args.list and (args.dataset or args.org):
        parser.error("--list cannot be combined with --dataset or --org")
    if (args.dataset and not args.org) or (args.org and not args.dataset):
        parser.error("--dataset and --org must be used together")

    datasets = load_datasets()
    organizations = load_organizations()

    if args.list:
        print("Available datasets:")
        for name, dataset in datasets.items():
            print(f"  {name:30s}  {dataset['description']}")
        print("\nAvailable organizations:")
        for name, org in organizations.items():
            print(f"  {name:30s}  {org['catalog_publisher']['name']}")
        sys.exit(0)

    if args.dataset not in datasets:
        sys.exit(f"[Error] Unknown dataset '{args.dataset}'. Run with --list to see available datasets.")
    if args.org not in organizations:
        sys.exit(f"[Error] Unknown organization '{args.org}'. Run with --list to see available organizations.")

    dataset_config = datasets[args.dataset]
    organization_config = organizations[args.org]

    now = time.strftime("%Y%m%d%H%M%S")
    run_datadump_pipeline(now, args.dataset, dataset_config, organization_config)
    if not args.skip_dcat:
        generate_dcat(now, args.dataset, dataset_config, args.org, organization_config)