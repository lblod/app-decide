import math
import time
from jinja2 import Environment, FileSystemLoader
env = Environment(loader=FileSystemLoader("."))

from concurrent.futures import ThreadPoolExecutor, as_completed
from rdflib import URIRef, Graph as RDFGraph
from helpers import insert_to_count, paginate_insert, query, select_rows, term_from_binding, update, log
from config import datadump_file_name, INSERT_BATCH_SIZE
from config import BATCH_SIZE, CONCURRENCY, OUTPUT_DIR, TMP_GRAPH

def _step1_populate_tmp_graph(insert_query: str, interesting_variables: list[str]) -> None:
    log("[Step 1] Counting distinct subjects (?%s) …", "  ?".join(interesting_variables))
    total_count = 0
    for var in interesting_variables:
        rows = select_rows(insert_to_count(insert_query, var))
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
            executor.submit(update, paginate_insert(insert_query, INSERT_BATCH_SIZE, i * INSERT_BATCH_SIZE)): i + 1
            for i in range(num_batches)
        }
        for future in as_completed(futures):
            future.result()
            completed += 1
            log("  [Step 1] %d/%d batches done", completed, num_batches)

    log("[Step 1] Done. %d distinct subject URIs queued.", total_count)


def _step2_fetch_batch() -> list[str]:
    q = f"""
SELECT DISTINCT ?subject WHERE {{
  GRAPH <{TMP_GRAPH}> {{
    ?subject ?p ?o .
  }}
}} LIMIT {BATCH_SIZE}
"""
    return [row["subject"] for row in select_rows(q)]

def _step3_construct_batch(subjects: list[str]) -> str:
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
        g.add((URIRef(row["s"]["value"]), URIRef(row["p"]["value"]), term_from_binding(row["o"])))
    return g.serialize(format="turtle")


def _step4_delete_batch(subjects: list[str]) -> None:
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


def generate_datadump(timestamp: str, dataset: str, dataset_config: dict, organization_config: dict) -> None:
    log("=== Dataset: %s ===", dataset_config['description'])
    output_file_name = dataset_config.get("output_file_name", dataset)

    insert_query = env.from_string(dataset_config["insert_query"]).render(
        organizationFilter=organization_config.get("organizationFilter", ""))

    _step1_populate_tmp_graph(insert_query, dataset_config["interesting_variables"])

    total = 0
    output_file = OUTPUT_DIR / datadump_file_name(output_file_name, timestamp)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as fh:
        while True:
            batch = _step2_fetch_batch()
            if not batch:
                log("[Pipeline] Tmp graph is empty – extraction complete.")
                break

            turtle = _step3_construct_batch(batch)
            fh.write(turtle)
            fh.write("\n")

            _step4_delete_batch(batch)

            total += len(batch)
            log("[Pipeline] Processed %d subjects …", total)
            time.sleep(0.1)

    log("[Datadump Pipeline] Finished. %d subjects written to '%s'.", total, output_file)
