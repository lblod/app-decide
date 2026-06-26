# Data extraction for municipality as .ttl

This mu script generates a datadump (in Turtle format) for each dataset (corresponding to a use case) of DECIDe. This datadump is published by the `datadumps` service. Also, DCAT information is added to the triple store, which is then published by the `ldes-serve-feed` service.

## What does a DECIDe partner need to do

Here is a list of things each partner must do:
* Update your city configuration in `config.json` with a `email` field who to contact, (optional) `sparql_endpoint` field if you choose to expose the SPARQL endpoint, and `datadump_base_url` field with the public URL of the datadumps. An example configuration looks as follows:

```application/json
"bamberg": {
    "catalog_uri": "http://data.lblod.info/id/catalogs/7a6b5c4d-3e2f-1a0b-9c8d-7e6f5a4b3c2d",
    "catalog_uuid": "7a6b5c4d-3e2f-1a0b-9c8d-7e6f5a4b3c2d",
    "catalog_publisher": {
        "uri": "https://opendata.smartcitybamberg.de/decide/organizations#c8e6b8ef-0a33-425a-b9d5-96354823f6e7",
        "name": "City of Bamberg",
        "email": "test@stad.bamberg.de"
    },
    "organizationFilter": "values ?participant { <https://opendata.smartcitybamberg.de/decide/organizations#c8e6b8ef-0a33-425a-b9d5-96354823f6e7> }",
    "sparql_endpoint": "https://decide.partner.eu/api/sparql",
    "datadump_base_url": "https://decide.partner.eu/datadumps/"
}
```

* Run the script for each dataset. Replace NAME with `gent`, `freiburg` or `bamberg`:
```
mu script project-scripts publish-dataset --dataset codelists --org NAME
mu script project-scripts publish-dataset --dataset rmz --org NAME
mu script project-scripts publish-dataset --dataset expressions --org NAME
mu script project-scripts publish-dataset --dataset human-validations --org NAME
mu script project-scripts publish-dataset --dataset codelists --org NAME
```

## Configuration

SPARQL connectivity, logging, and the `mu-auth-sudo` header are handled by `helpers.py` (modeled after `mu-python-template`'s `helpers` module) and configured via environment variables:

| Variable                 | Default                          | Purpose                                |
| ------------------------ | --------------------------------- | --------------------------------------- |
| `MU_SPARQL_ENDPOINT`     | `http://database:8890/sparql`     | `sparql-parser` query endpoint          |
| `MU_SPARQL_UPDATEPOINT`  | same as `MU_SPARQL_ENDPOINT`      | `sparql-parser` update endpoint         |
| `LOG_LEVEL`               | `INFO`                            | Python `logging` level                  |

Every `query`/`update` call sends a `mu-auth-sudo: true` header so it bypasses the ODRL policy enforced by `sparql-parser` — the script has no session of its own to be granted read/write access under and scopes are not yet supported using ODRL.

The remaining constants live at the top of `generate_datadump_and_dcat.py`:

| Variable            | Default                                | Purpose                             |
| ------------------- | -------------------------------------- | ----------------------------------- |
| `TMP_GRAPH`         | `http://mu.semte.ch/graphs/tmp-export` | Named graph used as processing queue   |
| `PUBLIC_GRAPH`      | `http://mu.semte.ch/graphs/public`     | Graph DCAT catalog/dataset data is written to |
| `OUTPUT_DIR`        | `/data/app/data/datadumps`             | Directory `.ttl` dataset dumps are written to |
| `BATCH_SIZE`        | `500`                                  | Subjects per CONSTRUCT/DELETE cycle |
| `INSERT_BATCH_SIZE` | `100000`                               | Rows per INSERT page                |
| `CONCURRENCY`       | `4`                                    | Parallel INSERT workers             |

Override any of these via environment variable, e.g.:

```bash
export MU_SPARQL_ENDPOINT=http://database:8890/sparql
```

## Usage

Make sure mu CLI is installed: https://github.com/mu-semtech/mu-cli
You could also manually run the script using the following docker command: `docker run --network app-decide_default -v ./:/data/app -v ./scripts/project/publish_dataset:/script  -it -w /script --rm --entrypoint ./build.sh python:3.12-slim --dataset codelists --org gent`.

```bash
# List all available datasets
mu script project-scripts publish-dataset --list

# Run a specific dataset for a certain organization 
mu script project-scripts publish-dataset --dataset codelists --org freiburg
mu script project-scripts publish-dataset --dataset rmz --org bamberg
mu script project-scripts publish-dataset --dataset expressions --org gent
mu script project-scripts publish-dataset --dataset human-validations --org abb

# Run a specific dataset WITHOUT generating DCAT using the --skip-dcat flag
mu script project-scripts publish-dataset --dataset codelists --org freiburg --skip-dcat
```

Output `.ttl` files are written to `OUTPUT_DIR` (`/data/app/data/datadumps` by default). `scripts/project/config.json` mounts the repo root (`$PWD` where `mu` is invoked) at `/data/app/` for this script, so this lands in `./data/datadumps` on the host, served publicly by the `datadumps` nginx container mounted on that same path.

Output DCAT is directly written to the triple store in the `PUBLIC_GRAPH` named graph.

> **Warning: scripts must not run concurrently.**
> All datasets share the same temporary named graph (`TMP_GRAPH`). Concurrent runs will cause scripts to read and delete each other's queue entries, producing incomplete or corrupted output. Always wait for one dataset to finish before starting the next.

## Available datasets

| Datasets                 | Description                                                                     | Output                                  |
| ------------------- | ------------------------------------------------------------------------------- | ---------------------------------------- |
| `codelists`         | Codelist annotations (by default: SDGs and impact)                              | `$OUTPUT_DIR/yyyymmddHHMMSS-codelists.ttl`         |
| `rmz`               | Restricted Mobility Zone (RMZ) Concept annotations + locations for municipality | `$OUTPUT_DIR/rmz.ttl`               |
| `expressions`       | ELI metadata (expression + work + manifestation)                                | `$OUTPUT_DIR/yyyymmddHHMMSS-expressions.ttl`       |
| `human-validations` | Human review annotations                                                        | `$OUTPUT_DIR/yyyymmddHHMMSS-human-validations.ttl` |

## Available organizations

`config.json` has a key `catalogs` where a DCAT catalog for each organization (gent, bamberg, freiburg, and abb) is listed. Inside `catalog_publisher`, the name and email of the organization can be defined. Inside `organizationFilter`, a filter can be defined for scoping the data extraction to one (or more) organizations. Four organizations are currently supported:

| Organization | URI                                                                                                             |
| ------------ | --------------------------------------------------------------------------------------------------------------- |
| Bamberg      | `<https://opendata.smartcitybamberg.de/decide/organizations#c8e6b8ef-0a33-425a-b9d5-96354823f6e7>`              |
| Freiburg     | `<https://ris.freiburg.de/oparl/body/FR>`                                                                       |
| Gent         | `<http://data.lblod.info/id/bestuurseenheden/353234a365664e581db5c2f7cc07add2534b47b8e1ab87c821fc6e6365e6bef5>` |
| Agency for Local Affairs (ABB)         | `<http://data.lblod.info/id/bestuurseenheden/141d9d6b-54af-4d17-b313-8d1c30bc3f5b>` |


## DCAT

For each `--dataset --org` run, DCAT metadata is written directly into `PUBLIC_GRAPH`, rendered from the Jinja templates in `templates/`:

| Template                        | Produces                                                                                        |
| -------------------------------- | ------------------------------------------------------------------------------------------------ |
| `templates/dcat-catalog.ttl.j2`  | One `dcat:Catalog` (+ its `foaf:Agent` publisher) per organization                               |
| `templates/dcat-dataset.ttl.j2`  | One `dcat:Dataset`, optionally a `dcat:Distribution` (data dump) and a `dcat:DataService` (SPARQL endpoint) |

```
Catalog (per org)
 └─ dcat:dataset → Dataset (per org + dataset)
      ├─ dcat:distribution → Distribution    (only if `datadump_base_url` is configured)
      └─ (catalog) dcat:service → DataService (only if `sparql_endpoint` is configured)
```

### Stable URIs

- `catalog_uri` / `catalog_uuid` are fixed values set per organization in `config.json`.
- The `dataset`, `service`, and `distribution` URIs/UUIDs are derived deterministically (`uuid.uuid5(NAMESPACE_URL, "<org>/<dataset>/<kind>")`) from the organization and the dataset's config key, so re-running the same `--dataset`/`--org` always resolves to the same URIs instead of minting duplicates.

### Re-running a dataset

If the catalog or dataset subject already exists in `PUBLIC_GRAPH`, the script deletes all of its existing triples and re-renders them from scratch — but it reads back the original `dct:issued` value first and keeps it, while `dct:modified` is set to the current run's timestamp.

### Required `config.json` fields per organization

| Field                 | Required | Description                             |
| --------------------- | -------- | --------------------------------------------------------------------------------- |
| `catalog_uri`         | yes      | URI of the DCAT catalog —                                                                                   |
| `catalog_uuid`        | yes      | UUID of the DCAT catalog —                                                                                   |
| `catalog_publisher`   | yes      | Contains fields `uri`, `name`, `email`, used as `dct:publisher`/`dcat:contactPoint` and rendered as a `foaf:Agent` |
| `organizationFilter`  | yes      | SPARQL `VALUES` block injected into the dataset's query (empty string = no filter) |
| `sparql_endpoint`     | no       | If not set, skips emitting the `dcat:DataService` for the SPARQL endpoint                        |
| `datadump_base_url`   | no       | If not set, skips emitting the `dcat:Distribution` for the data dump                           |

## Adding a new dataset

1. Create `queries/<name>.sparql` with an INSERT query that populates the tmp graph. Every subject URI you want to extract must be inserted with `a ext:downloadResource` as a marker:

   ```sparql
   PREFIX ext: <http://mu.semte.ch/vocabularies/ext/>
   PREFIX ex: <http://example.org/>

   INSERT {
     GRAPH <http://mu.semte.ch/graphs/tmp-export> {
       ?subject a ext:downloadResource .
     }
   } WHERE {
     ?subject a ex:SomeClass .
   }
   ```

If you want to filter on a certain codelist, you can find inspiration in the `queries/codelists.sparql` and `queries/rmz.sparql` queries.

2. Add an entry to `config.json`:

   ```json
   "my-dataset": {
     "description": "Human-readable label shown in --list",
     "output_file": "my-dataset",
     "sparql_file": "./queries/<name>.sparql",
     "interesting_variables": ["subject"]
   }
   ```

   `interesting_variables` is required — list every SPARQL variable from the INSERT head. Step 1 runs a `COUNT(DISTINCT ?var)` query per variable and sums the results to determine how many subjects will be extracted and how many INSERT batches to fire.

   For multi-subject datasets (e.g. expression + work + manifestation):

   ```json
   "interesting_variables": ["expression", "work", "manifests"]
   ```
