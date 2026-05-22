# Data extraction for municipality as .ttl

## Requirements

- Python 3.9+
- Access to a Virtuoso SPARQL endpoint (read + write)

## Configuration

Edit the constants at the top of `extract_ttl_to_file.py`:

| Variable            | Default                                | Purpose                             |
| ------------------- | -------------------------------------- | ----------------------------------- |
| `SPARQL_ENDPOINT`   | `http://localhost:8890/sparql`         | Virtuoso SPARQL endpoint            |
| `TMP_GRAPH`         | `http://mu.semte.ch/graphs/tmp-export` | Named graph used as the job queue   |
| `BATCH_SIZE`        | `500`                                  | Subjects per CONSTRUCT/DELETE cycle |
| `INSERT_BATCH_SIZE` | `100000`                               | Rows per INSERT page                |
| `CONCURRENCY`       | `4`                                    | Parallel INSERT workers             |

Or override the endpoint via environment variable:

```bash
export SPARQL_ENDPOINT=http://my-virtuoso-host:8890/sparql
```

## Usage

```bash
# List all available jobs
python extract_ttl_to_file.py --list

# Run a specific job
python extract_ttl_to_file.py --job sdgs
python extract_ttl_to_file.py --job expressions
python extract_ttl_to_file.py --job human-validations
```

Output `.ttl` files are written to `./output/`.

> **Warning: jobs must not run concurrently.**
> All jobs share the same temporary named graph (`TMP_GRAPH`). Running two jobs at the same time will cause them to read and delete each other's queue entries, resulting in incomplete or corrupted output. Always wait for one job to finish before starting the next.

## Available jobs

| Job                 | Description                                      | Output                         |
| ------------------- | ------------------------------------------------ | ------------------------------ |
| `sdgs`              | SDG Concept annotations for bestuurseenheid      | `output/sdgs.ttl`              |
| `expressions`       | ELI metadata (expression + work + manifestation) | `output/expressions.ttl`       |
| `human-validations` | Human review annotations                         | `output/human-validations.ttl` |

## Configuring municipalities

The queries in `queries/` use a `VALUES ?participant { ... }` block to scope extraction to one or more municipalities. Three municipalities are currently supported:

| Municipality | URI                                                                                                             |
| ------------ | --------------------------------------------------------------------------------------------------------------- |
| Bamberg      | `<https://opendata.smartcitybamberg.de/decide/organizations#c8e6b8ef-0a33-425a-b9d5-96354823f6e7>`              |
| Freiburg     | `<https://ris.freiburg.de/oparl/body/FR>`                                                                       |
| Gent         | `<http://data.lblod.info/id/bestuurseenheden/353234a365664e581db5c2f7cc07add2534b47b8e1ab87c821fc6e6365e6bef5>` |

To extract data for all three municipalities at once, update the `VALUES` block in the relevant `.sparql` file:

```sparql
values ?participant {
  <https://opendata.smartcitybamberg.de/decide/organizations#c8e6b8ef-0a33-425a-b9d5-96354823f6e7> # Bamberg
  <https://ris.freiburg.de/oparl/body/FR>                                                          # Freiburg
  <http://data.lblod.info/id/bestuurseenheden/353234a365664e581db5c2f7cc07add2534b47b8e1ab87c821fc6e6365e6bef5> # Gent
}
```

To extract a single municipality, keep only that URI in the block:

```sparql
values ?participant {
  <https://ris.freiburg.de/oparl/body/FR> # Freiburg only
}
```

### Running all three municipalities, one job at a time

```bash
# 1. Configure the VALUES block in each .sparql file to include all three URIs (see above)

# 2. Run each job sequentially — never in parallel
python extract_ttl_to_file.py --job sdgs
python extract_ttl_to_file.py --job expressions
python extract_ttl_to_file.py --job human-validations
```

Results will be merged in a single output file per job, covering all configured municipalities.

## Crash resilience

The temporary graph is a persistent checkpoint. If the script crashes mid-run, simply re-run the same job — it will skip already-processed subjects and continue from where it left off. If it crashed during Step 1 (populating the queue), re-running is still safe because duplicate inserts into the tmp graph are no-ops.

## Adding a new job

1. Create `queries/<name>.sparql` with an INSERT query that populates the tmp graph:

   ```sparql
   PREFIX ex: <http://example.org/>

   INSERT {
     GRAPH <http://mu.semte.ch/graphs/tmp-export> {
       ?subject a ?type .
     }
   } WHERE {
     ?subject a ex:SomeClass .
   }
   ```

2. Add an entry to `jobs.json`:
   ```json
   "my-job": {
     "description": "Human-readable label shown in --list",
     "output_file": "./output/my-job.ttl",
     "sparql_file": "./queries/my-job.sparql"
   }
   ```

No changes to `extract_ttl_to_file.py` are needed.
