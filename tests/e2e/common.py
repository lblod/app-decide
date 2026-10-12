#!/usr/bin/env python3
"""Helpers shared by the e2e pipeline tests."""
import argparse
import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from datetime import datetime, timezone
from pathlib import Path

ENDPOINT = os.environ.get("E2E_SPARQL_ENDPOINT", "http://localhost:8891/sparql")
MIGRATIONS_TIMEOUT = int(os.environ.get("E2E_MIGRATIONS_TIMEOUT", "900"))
PIPELINE_TIMEOUT = int(os.environ.get("E2E_PIPELINE_TIMEOUT", "1200"))
POLL_INTERVAL = 15
COMPOSE = os.environ.get(
    "COMPOSE", "docker compose -p app-decide-e2e -f docker-compose.yml -f docker-compose.e2e.yml")
MAX_NEW_RESTARTS = 3

JOBS_GRAPH = "http://mu.semte.ch/graphs/harvesting"
PUBLIC_GRAPH = "http://mu.semte.ch/graphs/public/pdf"
MIGRATIONS_DIR = Path(__file__).resolve().parents[2] / "config" / "migrations"
# Not under data/e2e: docker creates that as root when the labeling stack mounts it.
STATE_FILE = Path(tempfile.gettempdir()) / "app-decide-e2e-state.json"
MIGRATIONS_GRAPH = "http://mu.semte.ch/application"
MIGRATION_CLASS = "http://mu.semte.ch/vocabularies/migrations/Migration"
MIGRATION_FILENAME = "http://mu.semte.ch/vocabularies/migrations/filename"

STATUS = "http://redpencil.data.gift/id/concept/JobStatus/"
TASK_OP = "http://lblod.data.gift/id/jobs/concept/TaskOperation/"
JOB_CREATOR_SELF_SERVICE = "http://lblod.data.gift/services/job-self-service"

PREFIXES = """
PREFIX adms: <http://www.w3.org/ns/adms#>
PREFIX cogs: <http://vocab.deri.ie/cogs#>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX eli: <http://data.europa.eu/eli/ontology#>
PREFIX epvoc: <https://data.europarl.europa.eu/def/epvoc#>
PREFIX ext: <http://mu.semte.ch/vocabularies/ext/>
PREFIX gold: <http://purl.org/linguistics/gold/>
PREFIX hrvst: <http://lblod.data.gift/vocabularies/harvesting/>
PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
PREFIX nfo: <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#>
PREFIX nie: <http://www.semanticdesktop.org/ontologies/2007/01/19/nie#>
PREFIX oa: <http://www.w3.org/ns/oa#>
PREFIX org: <http://www.w3.org/ns/org#>
PREFIX oslc: <http://open-services.net/ns/core#>
PREFIX prov: <http://www.w3.org/ns/prov#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sh: <http://www.w3.org/ns/shacl#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX task: <http://redpencil.data.gift/vocabularies/tasks/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
"""


def sparql(text, update=False):
    body = urllib.parse.urlencode({"update" if update else "query": PREFIXES + text}).encode()
    request = urllib.request.Request(ENDPOINT, data=body, headers={
        "mu-auth-sudo": "true",
        "Accept": "application/sparql-results+json",
        "Content-Type": "application/x-www-form-urlencoded",
    })
    with urllib.request.urlopen(request, timeout=60) as response:
        payload = response.read()
    return None if update else json.loads(payload)


def ask(pattern):
    return sparql(f"ASK {{ {pattern} }}")["boolean"]


def select(text):
    return [{key: value["value"] for key, value in row.items()}
            for row in sparql(text)["results"]["bindings"]]


def last_migration_filename():
    """The last migration mu-migrations should run, by ascending leading number in the filename."""
    candidates = []
    for path in MIGRATIONS_DIR.rglob("*"):
        if not path.is_file():
            continue
        match = re.match(r"(\d+).*\.(sparql|ttl)$", path.name)
        if match:
            candidates.append((int(match.group(1)), path.name))
    return max(candidates)[1]


LAST_MIGRATION = last_migration_filename()


class ServiceCrashed(Exception):
    pass


def compose(*args):
    return subprocess.run(shlex.split(COMPOSE) + list(args),
                          capture_output=True, text=True, check=True).stdout


def container_states():
    try:
        containers = compose("ps", "--all", "-q").split()
        if not containers:
            return {}
        inspected = subprocess.run(
            ["docker", "inspect", "--format",
             '{{index .Config.Labels "com.docker.compose.service"}} '
             "{{.RestartCount}} {{.State.Status}} {{.State.ExitCode}}", *containers],
            capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"Container check unavailable: {error}")
        return {}
    states = {}
    for line in inspected.splitlines():
        service, restarts, status, exit_code = line.split()
        states[service] = (int(restarts), status, exit_code)
    return states


def restart_counts():
    return {service: state[0] for service, state in container_states().items()}


def check_containers(baseline=None):
    crashing = []
    for service, (restarts, status, exit_code) in container_states().items():
        detail = f"{restarts} restarts, {status}, exit code {exit_code}"
        # migrations has no restart policy, so a crash there shows as a non-zero exit.
        if status == "exited" and exit_code != "0":
            crashing.append((service, detail))
        # Services restart on purpose until the database is up, so only count restarts after that.
        elif baseline is not None and restarts - baseline.get(service, restarts) >= MAX_NEW_RESTARTS:
            crashing.append((service, detail))
    if crashing:
        raise ServiceCrashed(crashing)


def wait_for_migrations():
    deadline = time.monotonic() + MIGRATIONS_TIMEOUT
    while time.monotonic() < deadline:
        check_containers()
        try:
            if ask(f"""GRAPH <{MIGRATIONS_GRAPH}> {{
  ?m a <{MIGRATION_CLASS}> ; <{MIGRATION_FILENAME}> ?f .
}}
FILTER(STR(?f) = "{LAST_MIGRATION}")"""):
                return True
            print(f"Migrations not finished yet, waiting for {LAST_MIGRATION}")
        except (urllib.error.URLError, ConnectionError, TimeoutError) as error:
            print(f"Database not reachable yet: {error}")
        time.sleep(POLL_INTERVAL)
    return False

def new_resource(base):
    resource_id = str(uuid.uuid4())
    return base + resource_id, resource_id


def job_tasks(job):
    return select(f"""
SELECT ?task ?op ?status WHERE {{
  GRAPH <{JOBS_GRAPH}> {{
    ?task a task:Task ;
      dct:isPartOf <{job}> ;
      task:operation ?op ;
      adms:status ?status .
  }}
}}""")


def summary(rows):
    counts = {}
    for row in rows:
        key = f"{row['op'].removeprefix(TASK_OP)}={row['status'].removeprefix(STATUS)}"
        counts[key] = counts.get(key, 0) + 1
    return ", ".join(f"{key} x{count}" for key, count in sorted(counts.items())) or "no tasks yet"


def job_triples(job_op, input_containers, extra_job_triples=()):
    """A busy job and its scheduled singleton-job task, to insert into the jobs graph."""
    job, job_id = new_resource("http://redpencil.data.gift/id/job/")
    task, task_id = new_resource("http://redpencil.data.gift/id/task/")
    now = f'"{datetime.now(timezone.utc).isoformat()}"^^xsd:dateTime'
    extra = "".join(f" ;\n      {triple}" for triple in extra_job_triples)
    containers = ", ".join(f"<{container}>" for container in input_containers)
    return job, f"""
    <{job}> a cogs:Job ;
      mu:uuid "{job_id}" ;
      dct:created {now} ;
      dct:modified {now} ;
      dct:creator <{JOB_CREATOR_SELF_SERVICE}> ;
      adms:status <{STATUS}busy> ;
      task:operation <{job_op}>{extra} .
    <{task}> a task:Task ;
      mu:uuid "{task_id}" ;
      dct:created {now} ;
      dct:modified {now} ;
      adms:status <{STATUS}scheduled> ;
      task:operation <{TASK_OP}singleton-job> ;
      task:index "0" ;
      task:inputContainer {containers} ;
      dct:isPartOf <{job}> ."""


def stage_state(rows, stage, same_count_as=None):
    """done when every task of the stage succeeded, failed when any task of the job failed."""
    if any(row["status"] == STATUS + "failed" for row in rows):
        return "failed"
    tasks = [row for row in rows if row["op"] == TASK_OP + stage]
    if not tasks or any(row["status"] != STATUS + "success" for row in tasks):
        return "running"
    # A fan-out stage has one task per split batch, so wait until it caught up with the stage that split.
    if same_count_as and len(tasks) != sum(row["op"] == TASK_OP + same_count_as for row in rows):
        return "running"
    return "done"


def wait_for_stage(job, stage, same_count_as=None):
    deadline = time.monotonic() + PIPELINE_TIMEOUT
    rows = []
    baseline = restart_counts()
    while time.monotonic() < deadline:
        check_containers(baseline)
        try:
            rows = job_tasks(job)
            state = stage_state(rows, stage, same_count_as)
            print(f"[{state}] {summary(rows)}")
            if state != "running":
                return state, rows
        except (urllib.error.URLError, ConnectionError, TimeoutError) as error:
            print(f"Database not reachable yet: {error}")
        time.sleep(POLL_INTERVAL)
    return "timeout", rows


def print_errors(job):
    rows = select(f"""
SELECT ?op ?message WHERE {{
  GRAPH <{JOBS_GRAPH}> {{ ?task dct:isPartOf <{job}> ; task:operation ?op . }}
  {{
    ?task task:resultsContainer ?container .
    ?container task:hasResource ?error .
    ?error dct:description ?message .
  }} UNION {{
    ?task task:hasError ?error .
    ?error oslc:message ?message .
  }}
}}""")
    for row in rows:
        print(f"ERROR {row['op'].removeprefix(TASK_OP)}: {row['message']}")


def run_guarded(run_test):
    """Run a test, reporting any service that keeps crashing instead of a traceback."""
    try:
        return run_test()
    except ServiceCrashed as crash:
        for service, detail in crash.args[0]:
            print(f"FAIL: {service} keeps crashing ({detail}). Last log lines:")
            print(compose("logs", "--no-color", "--tail", "30", service))
        return 1


def migrations_step():
    print(f"Waiting for migrations to finish, up to {LAST_MIGRATION}")
    if wait_for_migrations():
        return 0
    print(f"FAIL: migrations did not reach {LAST_MIGRATION} before the migrations timeout")
    return 1


def seed_step(seed):
    state = seed()
    STATE_FILE.write_text(json.dumps(state), encoding="utf-8")
    print(f"Seeded job {state['job']}")
    return 0


def stage_step(stage, checks, fan_out):
    state = json.loads(STATE_FILE.read_text(encoding="utf-8"))
    same_count_as = fan_out[0] if fan_out and stage == fan_out[1] else None
    result, rows = wait_for_stage(state["job"], stage, same_count_as)
    if result != "done":
        print(f"FAIL: {stage} ended as {result}: {summary(rows)}")
        print_errors(state["job"])
        return 1
    failed = False
    for name, check in checks.get(stage, {}).items():
        passed = check(state)
        print(f"{'PASS' if passed else 'FAIL'}: {name}")
        failed = failed or not passed
    return 1 if failed else 0


def run_cli(chain, seed, checks, fan_out=None):
    """One command per workflow step: migrations, seed, or wait <stage> (with that stage's checks).

    seed() returns the state dict later steps read, including the job. checks maps a stage to
    {name: check(state)}. fan_out is (split stage, last stage) when one task per batch is created.
    """
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("migrations")
    commands.add_parser("seed")
    commands.add_parser("wait").add_argument("stage", choices=chain)
    args = parser.parse_args()
    if args.command == "migrations":
        step = migrations_step
    elif args.command == "seed":
        step = lambda: seed_step(seed)
    else:
        step = lambda: stage_step(args.stage, checks, fan_out)
    sys.exit(run_guarded(step))
