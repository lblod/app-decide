# DECIDe 

This repository contains all configuration to get the DECIDe microservices stack running. It is very much a work in progress. Below, documentation is provided for each use case.  

## What's included?

This repository contains multiple docker-compose files
- *docker-compose.yml* provides the backend components.
- *docker-compose.dev.yml* provides small changes for development purposes.
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

This README focuses on which services are needed to accomplish the DECIDE use cases. This way, a city can choose which services are desired to reuse for its own use cases.

For all use cases

In DECIDe, four use cases are defined. The first use case (0.0) is about converting and publishing decisions with Linked Data standards so these can be reused interoperable in the data space. The three other use cases (0.1, 1, and 2) are AI-enabled services to enrich the decisions.

### Use Case 0.0: Building up the Data Space

This use case retrieves decisions from a data source, and maps the decisions to the European Legislation Identifier (ELI) standard. For each city, a specific conversion pipeline is defined, because the input data sources are heterogeneous.

#### OSLO (Ghent)

To harvest and convert the decisions from the city of Ghent to ELI, a central data endpoint in Flanders for decisions (Lokaal Beslist) is used. Three services are required to consume, filter on a city, and transform to ELI: lokaal-beslist-consumer (a configured delta consumer), decisions-ghent-filter, and oslo-eli-transformer. See `docker-compose.yml` for the specific configuration. The initial sync and/or delta ingest should be enabled manually in `docker-compose.override.yml`:

```yml
services:
  lokaal-beslist-consumer:
    environment:
      DCR_DISABLE_INITIAL_SYNC: false
      DCR_DISABLE_DELTA_INGEST: false
```

Note: the AI services (used in the other use cases) will be made configurable to directly work with OSLO-compliant data

#### OParl (Freiburg)



#### PDF (Bamberg)


### Use Case 0.1: Linking to higher legislation or overarching goals such as the SDGs

AI-supported enrichment to link decisions to related things (legislation, themes, locations)

### Use Case 1: Mapping Local Decisions on restricted mobility zones to geo-locations for city portals (mobility and green deal)

### Use Case 2: Subsidies for Private Owners – Climate Change and Environment (Green deal)





## Configuring the dashboard
### Accessing the dashboard from your local machine

Since we use dispatcher v2, which dispatches on hostname, we'll have to update `/etc/hosts`.
Add an entry similar to the following. Ensure the first part of the domain starts with `dashboard`.:

```
127.0.0.1 dashboard.localhost
```