# Generic SPARQL-to-CSV export

This mu script runs a configured SPARQL SELECT query and writes its result set to a CSV file. Any dataset can be added by registering a `.sparql` file in `config.json` — nothing about the script itself is tied to a specific dataset. It's currently configured with datasets exporting human validation review results (approve/reject counts) for different annotation types, and an AI call log, but new datasets need no code changes, only a new `config.json` entry (see "Adding a new dataset" below).

Unlike `publish_dataset`, exports here are not published as open data — no DCAT, no per-organization split.

## Usage

Make sure mu CLI is installed: https://github.com/mu-semtech/mu-cli
You could also manually run the script using the following docker command: `docker run --network app-decide_default -v ./:/data/app -v ./scripts/project/export_csv:/script -it -w /script --rm lblod/python-semantic-works-cli:0.0.1 python3 export_csv.py --dataset codelist-labeling-validations`.

```bash
# List all available datasets
mu script project-scripts export-csv --list

# Export a specific dataset
mu script project-scripts export-csv --dataset codelist-labeling-validations
mu script project-scripts export-csv --dataset entity-linking-validations
mu script project-scripts export-csv --dataset smart-search-question-validations
mu script project-scripts export-csv --dataset smart-search-quotation-validations
mu script project-scripts export-csv --dataset ai-calls
```

Output `.csv` files are written to `OUTPUT_DIR` (`/data/app/data/csv-exports` by default). `scripts/project/config.json` mounts the repo root (`$PWD` where `mu` is invoked) at `/data/app/` for this script, so this lands in `./data/csv-exports` on the host.

## Currently configured datasets

| Dataset                              | Description                                       | Paginated |
| ------------------------------------- | -------------------------------------------------- | --------- |
| `codelist-labeling-validations`       | Codelist labeling human validation results         | yes       |
| `entity-linking-validations`          | Entity linking human validation results            | yes       |
| `smart-search-question-validations`   | Smart search question human validation summary     | no        |
| `smart-search-quotation-validations`  | Smart search quotation human validation summary    | no        |
| `ai-calls`                            | AI call log (operation, model, tokens, cost, timing) | yes     |

The row-level datasets can return a large number of rows, so they're fetched in batches (see below). The two summary datasets return a single aggregate row and are run once.

## Batching

Datasets flagged `paginated: true` in `config.json` are fetched in pages of `BATCH_SIZE` rows using `LIMIT`/`OFFSET`, appended to the query at runtime — the `.sparql` files themselves have no `LIMIT`. Pagination over a `GROUP BY` result set is only reliable with a matching `ORDER BY`, so any paginated query's `.sparql` file must end with an `ORDER BY` on the same variables as its `GROUP BY`. Rows are streamed to the CSV file batch by batch (the file is written incrementally, not held in memory), and fetching stops once a batch returns fewer than `BATCH_SIZE` rows.

Datasets flagged `paginated: false` are run once with no `LIMIT`/`OFFSET` — use this for aggregate/summary queries that always return a small, fixed number of rows.

## Configuration

SPARQL connectivity, logging, and the `mu-auth-sudo` header are handled by `helpers.py` (modeled after `publish_dataset`'s `helpers.py`) and configured via environment variables:

| Variable                | Default                          | Purpose                                 |
| ------------------------ | --------------------------------- | ---------------------------------------- |
| `MU_SPARQL_ENDPOINT`     | `http://database:8890/sparql`     | `sparql-parser` query endpoint           |
| `LOG_LEVEL`              | `INFO`                            | Python `logging` level                   |

Every `query` call sends a `mu-auth-sudo: true` header so it bypasses the ODRL policy enforced by `sparql-parser` — the script has no session of its own to be granted read access under.

The remaining constants live at the top of `export_csv.py`:

| Variable      | Default                     | Purpose                             |
| -------------- | ----------------------------- | ------------------------------------ |
| `BATCH_SIZE`  | `1000`                        | Rows per page for paginated datasets |
| `OUTPUT_DIR`  | `/data/app/data/csv-exports`  | Directory `.csv` files are written to |

Override any of these via environment variable, e.g.:

```bash
export BATCH_SIZE=500
```

## Adding a new dataset

1. Create `queries/<name>.sparql` with a SELECT query. If it's a `GROUP BY` query expected to return many rows, add a matching `ORDER BY` and do not include a `LIMIT`/`OFFSET` — those are injected dynamically at runtime for paginated datasets.

2. Add an entry to `config.json`:

   ```json
   "my-dataset": {
     "description": "Human-readable label shown in --list",
     "sparql_file": "./queries/<name>.sparql",
     "output_file_name": "my-dataset",
     "paginated": true
   }
   ```

   Set `"paginated": false` for queries that return a single (e.g. aggregate) row and don't need `LIMIT`/`OFFSET` pagination.

3. Run it: `mu script project-scripts export-csv --dataset my-dataset`.