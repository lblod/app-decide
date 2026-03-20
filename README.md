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

## Use cases

The DECIDe project is designed to address a set of pre-defined use cases. This README outlines each service individually, allowing cities to select and deploy only the specific components required for their unique needs.

The services defined at the top of the `docker-compose.yml` file are the core _Semantic.Works_ services required for running the project. In addition to the core service, we also need the generic pipeline components to run the pipelines. To configure the dashboard for your pipelines, see [below](##configuring-the-dashboard).

In DECIDe, four use cases are defined. The first use case (0.0) is about converting and publishing decisions with Linked Data standards so these can be reused interoperable in the data space. The three other use cases (0.1, 1, and 2) are AI-enabled services to enrich the decisions with related things, such as policies, themes, and locations.

### Use Case 0.0: Building up the Data Space

This use case retrieves decisions from a data source, and maps the decisions to the European Legislation Identifier (ELI) standard. Because the input data sources are heterogeneous a specific conversion pipeline is defined for each city.

#### OSLO (Ghent)

To harvest and convert decisions from the city of Ghent to ELI, a central data endpoint in Flanders for decisions (Lokaal Beslist) is used. Three services are required to consume this data, filter it for a specific city (currently only Ghent is supported), and transform it to ELI. See `docker-compose.yml` for the specific configuration.

1. `singleton-job`: This service is used to guarantee no two same jobs are running at the same time.
2. `lokaal-beslist-consumer`: A [configurable consumer](https://github.com/lblod/decide-harvester-consumer-service) that ingests harvester tasks and injests decision data from the central Flanders "Lokaal Beslist" endpoint into our local landing database.
3. `decisions-ghent-filter`: A [filtering service](https://github.com/lblod/decide-harvester-filter-service) that identifies and extracts only the decisions belonging to the city of Ghent from the ingested metadata stream.
4. `oslo-eli-transformer`: [This service](https://github.com/lblod/decide-harvester-transformation-service) transforms Ghent's OSLO-formatted decisions into the standardized ELI format used for further AI processing.

To summarize, this pipeline connects to the existing Lokaal Beslist infrastructure, filters the high-volume stream specifically for Ghent's decisions, and transforms them from the OSLO standard into the ELI format used internally.

> Note: the AI services (used in the other use cases) will be configurable so they can directly work with OSLO-compliant data

The OSLO configuration depends on consuming all data from a full LBLOD harvester. This results in a lot of extra data that is not necessary, see ./OSLO_PRUNING.md for info on how to reduce the database size after initial load.

##### Consumer

In essence, a consumer service makes its own copy of the data provided by a producer. In this case, the consumer is configured to take in all data from the Lokaal Beslist producer. This producer holds all decision data from local governments in Flanders.

All consumed data is stored in a configurable graph (`LANDING_GRAPH`). The next tasks in the pipeline rely on it.

The consumer service can be triggered in one or two ways, by firing an initial sync or a delta sync.

**Initial sync**:
An initial sync operation takes in **all data** that the producer has available at that moment in time. Depending on the size of the dataset, this might take some time. Usually, the initial sync needs to be run only once. When finished, the consumer stores the current datetime in order for a future delta sync operation to know which moment in time to proceed from.

**Delta sync**:
A delta sync operation brings the dataset **up to date** (inserts/deletes), starting from the last registered timestamp. When finished, the consumer stores a new timestamp, ready for the next delta sync operation.

In order to keep the dataset up to date throughout time, a delta sync operation should be triggered at regular intervals. It is therefore suitable to configure this pipeline as a scheduled job.

To make sure the next tasks in the pipeline can focus specifically on the new data inserted by a delta sync (and not the entire landing graph), that same data is also inserted in a temporary graph. This temporary graph is provided to the next service in line.

> Since decisions should never receive partial updates, we don't expect Lokaal Beslist to deliver any of those. The temporary graph created during delta sync therefore only holds **inserted** data, and the final transformation service will always **create** resources/properties (not update or delete).

#### Filter

The filter service allows to configure which resources should effectively be transformed in the next step. It does this by running a **SPARQL select query** on the consumer's landing graph, and writes the resulting resource URIs to a new temporary graph.

In case the service detects an input graph from the previous step (cfr. delta sync), it will **restrict** the query run on the landing graph to only inspect the resources listed in that input graph.

The filter service's **default** SPARQL select query looks for **`besluit:Besluit` instances** that belong to **Ghent** administrative bodies.

#### Transformer

The transformation service allows to configure several **SPARQL insert-where queries**. Each of these looks for resources/properties in the consumer's landing graph and inserts them (usually in a new *format*) in a configured output graph.

> While it would in theory be possible to provide a single large insert-where query, it is advised to work with multiple smaller ones, as the triplestore might struggle with large queries on large input graphs.

The SPARQL insert-where queries are further **restricted** to take into account only those resources that appear in the temporary graph provided by the filter service.

The transformation service's **default** SPARQL insert-where queries map specific **`besluit:Besluit` properties to `eli:Expression` and/or `eli:Work` properties**. In fact, the service doesn't create completely new resources, but instead *expands* the existing `besluit:Besluit` resources with ELI properties (type definitions included). Still, the fact that the transformation service writes to a different output graph than the consumer's landing graph, divides the original OSLO data from the newly created ELI data.

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

### Accessing the dashboard from your local machine

Since we use dispatcher v2, which dispatches on hostname, we'll have to update `/etc/hosts`.
Add an entry similar to the following. Ensure the first part of the domain starts with `dashboard`.:

```
127.0.0.1 dashboard.localhost
```

### Jobs

There are two types of jobs: harvesting and scheduled. The harvesting job is a one-time run of a job, while the scheduled job is triggered periodically following a cron pattern.

By pressing "Create new job", a job type ("operation") can be selected to create a new job.

![alt text](doc/dashboard-create-new-2.png)
