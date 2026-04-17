# DECIDe

This repository contains all configuration to get the DECIDe microservices stack running. It is very much a work in progress. Documentation for each use case is provided below.

## What's included?

This repository contains multiple docker-compose files

- _docker-compose.yml_ provides the backend components.
- _docker-compose.dev.yml_ provides small changes for development purposes.
  - Publishes the entrypoint to the services on port 80, so all endpoints can be reached easily.
  - Publishes the triplestore on port 8890, so the SPARQL endpoint (`/sparql`) can be reached easily.

## Running

### Getting started

1. Clone the repository and go into the directory
2. To ease all typing for `docker compose` commands create a compose override file in the root of the project

```bash
touch docker-compose.override.yml
```

3. Create an env file so we can define the compose files and other environment variables

```bash
touch .env
```

4. Set the `COMPOSE_FILE` in the .env

```bash
COMPOSE_FILE=docker-compose.yml:docker-compose.dev.yml:docker-compose.override.yml
```

### Running the stack

This should be your go-to way of starting the stack.

```bash
docker compose up -d # run without -d flag when you don't want to run it in the background
```

### Running on mac silicon

Running the application on mac silicon can cause some troubles. For this reason an extra docker-compose file has been included, this is the file docker-compose.mac.yml, this file should be included when starting the stack. The command `docker-compose up -f docker-compose.yml -f docker-compose.dev.yml up -d` now becomes `docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.mac.yml up -d`
There are two main pain points:

1. Mac has an arm64 processor, a lot of the services don't have a multi-platform image. In the case they only have a amd64 image, docker will gave you a warning about this. In general this is not a real problem since your macbook can just emulate amd64, but still the warnings are annoying, so these are suppressed.
2. At the moment this project was setup the service mu-identifier weren't working for mac (at least on my device), so you have to build these yourself, and gave them the appropriate image name and tag.

### Running the stack with smart search/question-answering

To get the stack to work properly, including its AI question-answering service, there are a few extra steps that need to be done.

First, add your LLM of choice (e.g., `gemma3:1b`) to your `docker-compose.override.yml`:

```
question-answering:
  image: semanticai/decide-question-answering:latest
  environment:
    SEARCH_API_URL: "http://search:80/expressions/large-search"
    EMBEDDING_API_URL: "http://embedding:80/embed"
    MU_SPARQL_ENDPOINT: "http://database:8890/sparql"
    MU_SPARQL_TIMEOUT: "30"
    GENERATION_PROVIDER: "ollama"
    GENERATION_ENDPOINT: "http://ollama:11434"
    GENERATION_MODEL: "gemma3:1b"
    GENERATION_TIMEOUT: "300.0"
    MAX_CONTENT_CHARS: "1000"
    REQUEST_TIMEOUT: "60.0"
    ALLOW_MU_AUTH_SUDO: "true"
```

To include (smart) search features, the stack needs to be started with the `search` profile: `drc --profile=search up -d`.

However, to avoid issues of started services waiting for the database and/or elasticsearch, it is advisable to start the stack in a 'staggered' manner:
```
docker compose --profile=search up -d virtuoso
docker compose --profile=search up -d database identifier dispatcher resource
docker compose --profile=search up -d search elasticsearch
```

After `search` has started, inspect the logs to ensure it is not indexing, for example when you are using an existing dataset: `docker compose logs -f search`.

When everything is up, you need to manually pull the model you entered in `docker-compose.override.yml` in the `ollama` container:
```
docker compose exec -T ollama ollama pull gemma3:1b
```

Finally, you need to restart the `embedding` service and ensure it runs error-free:
```
docker compose restart embedding
docker compose logs -f embedding
```

The frontend for the Smart Search should now be available at http://smart-search.localhost .

## Use cases

The DECIDe project is designed to address a set of pre-defined use cases. This README outlines each service individually, allowing cities to select and deploy only the specific components required for their unique needs.

The services defined at the top of the `docker-compose.yml` file are the core _Semantic.Works_ services required for running the project. In addition to the core service, we also need the generic pipeline components to run the pipelines. To configure the dashboard for your pipelines, see [below](##configuring-the-dashboard).

In DECIDe, four use cases are defined. The first use case (0.0) is about converting and publishing decisions with Linked Data standards so these can be reused interoperable in the data space. The three other use cases (0.1, 1, and 2) are AI-enabled services to enrich the decisions with related things, such as policies, themes, and locations.

### Use Case 0.0: Building up the Data Space

This use case retrieves decisions from a data source, and maps the decisions to the European Legislation Identifier (ELI) standard. Because the input data sources are heterogeneous a specific conversion pipeline is defined for each city.

#### OSLO (Ghent)

To harvest and convert the decisions from the city of Ghent to ELI, a central data endpoint in Flanders for decisions (Lokaal Beslist) is used. Three services are required to consume, filter on a city (currently only Ghent is supported), and transform to ELI: lokaal-beslist-consumer (a configured delta consumer), decisions-ghent-filter, and oslo-eli-transformer. See `docker-compose.yml` for the specific configuration. The initial sync and/or delta ingest should be enabled manually in `docker-compose.override.yml`:

```yml
services:
  lokaal-beslist-consumer:
    environment:
      DCR_DISABLE_INITIAL_SYNC: false
      DCR_DISABLE_DELTA_INGEST: false
```

Note: the AI services (used in the other use cases) will be configurable so they can directly work with OSLO-compliant data

The OSLO configuration depends on consuming all data from a full LBLOD harvester. This results in a lot of extra data that is not necessary, see ./OSLO_PRUNING.md for info on how to reduce the database size after initial load.

#### OParl (Freiburg)

The OParl to ELI pipeline consists of multiple services. The main service is the `oparl-to-eli` service, which scrapes all pages from an OParl API, transforms to ELI, and writes to files for further processing.
Next, the `harvest_singleton-job` service is used to prevent overlapping harvest rounds. The `harvest_sameas` service is used for two things: adding a local identifier (UUID) to each OParl entity, and importing the data in the triple store. The `harvest_diff` generates which triples are deleted, or new to make sure the triple store is in sync with the OParl source.

To start the OParl pipeline, create a "Harvest OParl API & Publish as ELI" job in the pipeline dashboard. Only an "URL" parameter is required. This can be the root OParl URL (`https://ris.freiburg.de/oparl`), or a more specific OParl URL (`https://ris.freiburg.de/oparl/Body/FR/paper`).

#### PDF (Bamberg)

The PDF to ELI pipeline requires three services. The `harvest_singleton-job` service is used, similar to the other pipelines, to guarantee a data source is harvested only once. The `pdf-content` service reads a remote or local PDF file, extracts the content of the PDF, and creates ELI entities (Work/Expression/Manifestation) in the triple store. The `apache-tika` service is used by the `pdf-content` service that is responsible for extracting text from a PDF.

In the pipeline dashboard, create a "Harvest PDF & Publish as ELI" pipeline. The URL parameter needs to be provided with a URL resolving with a PDF.

In the future a PDF pipeline will be added to harvest all PDFs from a website.

### Use Case 0.1: Linking to higher legislation or overarching goals such as the SDGs

In the pipeline dashboard, create a "Codelist mapping" pipeline. First, the `Codelist` parameter needs to be filled in with the URI of a SKOS Concept scheme. For Sustainable Development Goals (SDGs), this is `http://metadata.un.org/sdg`. Optionally, a `Decision to map` can be provided to map a specific decision with the codelist. This must be a URI of an ELI Work or Expression.

To show how decisions are linked with SDGs, a Policy impact report tool is being developed.

### Use Case 1: Mapping Local Decisions on restricted mobility zones to geo-locations for city portals (mobility and green deal)

### Use Case 2: Subsidies for Private Owners – Climate Change and Environment (Green deal)

## Pipeline dashboard

### Jobs

There are two types of jobs: harvesting and scheduled. The harvesting job is a one-time run of a job, while the scheduled job is triggered periodically following a cron pattern.

By pressing "Create new job", a job type ("operation") can be selected to create a new job.

![alt text](doc/dashboard-create-new-2.png)

## Frontends

### Accessing the frontends from your local machine

We use dispatcher v2, which dispatches different frontends based on hostname. If this does not work out of the box, you may have to add an entry similar to the following to your `/etc/hosts`:

```
127.0.0.1 dashboard.localhost
127.0.0.1 ds.localhost
127.0.0.1 human-validator.localhost
127.0.0.1 yasgui.localhost
```
