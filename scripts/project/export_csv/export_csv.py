#!/usr/bin/env python3
import argparse
import csv
import json
import os
import sys
import time
from pathlib import Path

from helpers import log, query

BATCH_SIZE = int(os.environ.get("BATCH_SIZE", 1000))

CONFIG_DIR = Path(__file__).parent
CONFIG_FILE = CONFIG_DIR / "config.json"
# scripts/project/config.json mounts $PWD (the repo root mu-cli is run from) at
# /data/app/ — not /app — so this lands in ./data/csv-exports on the host.
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", "/data/app/data/csv-exports"))


def load_datasets() -> dict:
    if not CONFIG_FILE.exists():
        sys.exit(f"[Error] config file not found: {CONFIG_FILE}")

    with open(CONFIG_FILE, encoding="utf-8") as fh:
        datasets = json.load(fh)["datasets"]

    for name, dataset in datasets.items():
        sparql_file = CONFIG_DIR / dataset["sparql_file"]
        if not sparql_file.exists():
            sys.exit(
                f"[Error] sparql file for dataset '{name}' not found: {sparql_file}"
            )
        dataset["query"] = sparql_file.read_text(encoding="utf-8")

    return datasets


# Datatypes rendered with a comma instead of a dot as the decimal separator,
# so numeric columns import correctly into Belgian-locale Excel (which reads
# a dot as a thousands separator, not a decimal point).
_COMMA_DECIMAL_DATATYPES = {
    "http://www.w3.org/2001/XMLSchema#decimal",
    "http://www.w3.org/2001/XMLSchema#double",
    "http://www.w3.org/2001/XMLSchema#float",
}


def _format_binding(binding: dict) -> str:
    value = binding["value"]
    if binding.get("datatype") in _COMMA_DECIMAL_DATATYPES:
        return value.replace(".", ",")
    return value


def select_rows_with_vars(q: str) -> tuple[list[str], list[dict]]:
    result = query(q)
    variables = result["head"]["vars"]
    rows = [
        {k: _format_binding(v) for k, v in row.items()} for row in result["results"]["bindings"]
    ]
    return variables, rows


def paginate(query_text: str, limit: int, offset: int) -> str:
    return f"{query_text.rstrip()}\nLIMIT {limit}\nOFFSET {offset}\n"


def output_file_for(dataset: str, dataset_config: dict, timestamp: str) -> Path:
    output_file_name = dataset_config.get("output_file_name", dataset)
    return OUTPUT_DIR / f"{timestamp}-{output_file_name}.csv"


def run_export(dataset: str, dataset_config: dict, timestamp: str) -> None:
    log("=== Dataset: %s ===", dataset_config["description"])
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output_file = output_file_for(dataset, dataset_config, timestamp)

    writer = None
    total = 0
    with open(output_file, "w", encoding="utf-8", newline="") as fh:
        if dataset_config.get("paginated"):
            offset = 0
            while True:
                variables, rows = select_rows_with_vars(
                    paginate(dataset_config["query"], BATCH_SIZE, offset)
                )
                if writer is None:
                    writer = csv.DictWriter(fh, fieldnames=variables, delimiter=";")
                    writer.writeheader()
                for row in rows:
                    writer.writerow(row)
                total += len(rows)
                if rows:
                    log("[Pipeline] Processed %d rows …", total)
                if len(rows) < BATCH_SIZE:
                    break
                offset += BATCH_SIZE
        else:
            variables, rows = select_rows_with_vars(dataset_config["query"])
            writer = csv.DictWriter(fh, fieldnames=variables, delimiter=";")
            writer.writeheader()
            for row in rows:
                writer.writerow(row)
            total = len(rows)

    log("[Pipeline] Finished. %d rows written to '%s'.", total, output_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Export a configured SPARQL query's results as CSV.",
        epilog="Example: mu script project-scripts export-csv --dataset codelist-labeling-validations",
    )
    parser.add_argument("--dataset", help="Dataset to export")
    parser.add_argument("--list", action="store_true", help="List available datasets")
    args = parser.parse_args()

    if args.list and args.dataset:
        parser.error("--list cannot be combined with --dataset")

    datasets = load_datasets()

    if args.list:
        print("Available datasets:")
        for name, dataset in datasets.items():
            print(f"  {name:35s}  {dataset['description']}")
        sys.exit(0)

    if not args.dataset:
        parser.error("--dataset is required (or use --list to see available datasets)")

    if args.dataset not in datasets:
        sys.exit(
            f"[Error] Unknown dataset '{args.dataset}'. Run with --list to see available datasets."
        )

    dataset_config = datasets[args.dataset]
    now = time.strftime("%Y%m%d%H%M%S")
    run_export(args.dataset, dataset_config, now)
