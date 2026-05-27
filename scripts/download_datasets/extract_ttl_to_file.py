import urllib.request
import urllib.parse
import urllib.error
import argparse
import json
import math
import time
import sys
import os
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

SPARQL_ENDPOINT   = os.environ.get("SPARQL_ENDPOINT", "http://localhost:8890/sparql")
TMP_GRAPH         = "http://mu.semte.ch/graphs/tmp-export"
BATCH_SIZE        = 500
INSERT_BATCH_SIZE = 100000
CONCURRENCY       = 4

JOBS_DIR        = Path(__file__).parent / "./"
JOBS_FILE       = JOBS_DIR / "jobs.json"

def load_jobs() -> dict:
    if not JOBS_FILE.exists():
        sys.exit(f"[Error] jobs file not found: {JOBS_FILE}")

    with open(JOBS_FILE, encoding="utf-8") as fh:
        jobs = json.load(fh)

    for name, job in jobs.items():
        sparql_file = JOBS_DIR / job["sparql_file"]
        if not sparql_file.exists():
            sys.exit(f"[Error] sparql file for job '{name}' not found: {sparql_file}")
        job["insert_query"] = sparql_file.read_text(encoding="utf-8")

    return jobs

def _sparql_request(query: str) -> str:
    data = urllib.parse.urlencode({"query": query}).encode()
    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept":        "application/sparql-results+json",
    }
    req = urllib.request.Request(SPARQL_ENDPOINT, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return resp.read().decode()
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        raise RuntimeError(f"HTTP {e.code} from SPARQL endpoint:\n{body}") from e


def sparql_update(query: str) -> None:
    data = urllib.parse.urlencode({"update": query}).encode()
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    req = urllib.request.Request(SPARQL_ENDPOINT, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            resp.read()
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        raise RuntimeError(f"HTTP {e.code} from SPARQL endpoint:\n{body}") from e


def sparql_select(query: str) -> list[dict]:
    raw      = _sparql_request(query)
    result   = json.loads(raw)
    bindings = result["results"]["bindings"]
    return [{k: v["value"] for k, v in row.items()} for row in bindings]


def sparql_construct(query: str) -> str:
    data = urllib.parse.urlencode({"query": query}).encode()
    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept":        "text/turtle",
    }
    req = urllib.request.Request(SPARQL_ENDPOINT, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return resp.read().decode()
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        raise RuntimeError(f"HTTP {e.code} from SPARQL endpoint:\n{body}") from e

def _insert_to_count(insert_query: str, interesting_variable: str) -> str:
    upper      = insert_query.upper()
    insert_pos = upper.index("INSERT")
    where_pos  = upper.index("WHERE", insert_pos)
    prefixes   = insert_query[:insert_pos]
    where_body = insert_query[where_pos:].rstrip()
    assert where_body.endswith("}"), "WHERE clause must end with }"
    return prefixes + f"SELECT (COUNT(DISTINCT ?{interesting_variable}) AS ?n) " + where_body + "\n"


def _paginate_insert(insert_query: str, limit: int, offset: int) -> str:
    body = insert_query.rstrip()
    assert body.endswith("}"), "INSERT query must end with the closing WHERE brace }"
    return body + f"\nLIMIT {limit} OFFSET {offset}\n"


def step1_populate_tmp_graph(insert_query: str, interesting_variables: list[str]) -> None:
    print(f"[Step 1] Counting distinct subjects (?{'  ?'.join(interesting_variables)}) …")
    total_count = 0
    for var in interesting_variables:
        rows = sparql_select(_insert_to_count(insert_query, var))
        n = int(rows[0]["n"]) if rows else 0
        print(f"  [Step 1] ?{var}: {n} distinct")
        total_count += n

    if total_count == 0:
        print("[Step 1] Nothing to queue.")
        return

    num_batches = math.ceil(total_count / INSERT_BATCH_SIZE)
    print(f"[Step 1] {total_count} distinct subject URIs → {num_batches} batch(es) of {INSERT_BATCH_SIZE} ({CONCURRENCY} parallel)")

    completed = 0
    with ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
        futures = {
            executor.submit(sparql_update, _paginate_insert(insert_query, INSERT_BATCH_SIZE, i * INSERT_BATCH_SIZE)): i + 1
            for i in range(num_batches)
        }
        for future in as_completed(futures):
            future.result()
            completed += 1
            print(f"\r  [Step 1] {completed}/{num_batches} batches done", end="", flush=True)

    print(f"\n[Step 1] Done. {total_count} distinct subject URIs queued.")


def step2_fetch_batch() -> list[str]:
    query = f"""
SELECT DISTINCT ?subject WHERE {{
  GRAPH <{TMP_GRAPH}> {{
    ?subject ?p ?o .
  }}
}} LIMIT {BATCH_SIZE}
"""
    return [row["subject"] for row in sparql_select(query)]


def step3_construct_batch(subjects: list[str]) -> str:
    values = " ".join(f"<{s}>" for s in subjects)
    query = f"""
CONSTRUCT {{
  ?subject ?p ?o .
}} WHERE {{
  VALUES ?subject {{ {values} }}
  ?subject ?p ?o .
  FILTER NOT EXISTS {{
    GRAPH <{TMP_GRAPH}> {{ ?subject ?p ?o . }}
  }}
}}
"""
    return sparql_construct(query)


def step4_delete_batch(subjects: list[str]) -> None:
    values = " ".join(f"<{s}>" for s in subjects)
    query = f"""
DELETE {{
  GRAPH <{TMP_GRAPH}> {{ ?subject ?p ?o . }}
}}
WHERE {{
  GRAPH <{TMP_GRAPH}> {{ ?subject ?p ?o . }}
  VALUES ?subject {{ {values} }}
}}
"""
    sparql_update(query)

def run_pipeline(job: dict) -> None:
    print(f"\n=== Job: {job['description']} ===\n")
    output_file = job.get("output_file", "output.ttl")

    step1_populate_tmp_graph(job["insert_query"], job["interesting_variables"])

    total = 0
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as fh:
        while True:
            batch = step2_fetch_batch()
            if not batch:
                print("[Pipeline] Tmp graph is empty – extraction complete.")
                break

            turtle = step3_construct_batch(batch)
            fh.write(turtle)
            fh.write("\n")

            step4_delete_batch(batch)

            total += len(batch)
            print(f"\r[Pipeline] Processed {total} subjects …", end="", flush=True)
            time.sleep(0.1)

    print(f"\n[Pipeline] Finished. {total} subjects written to '{output_file}'.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Queue Graph extraction pipeline")
    group  = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--job",  help="Job name to run")
    group.add_argument("--list", action="store_true", help="List available jobs")
    args = parser.parse_args()

    jobs = load_jobs()

    if args.list:
        print("Available jobs:")
        for name, job in jobs.items():
            print(f"  {name:30s}  {job['description']}")
        sys.exit(0)

    if args.job not in jobs:
        sys.exit(f"[Error] Unknown job '{args.job}'. Run with --list to see available jobs.")

    run_pipeline(jobs[args.job])