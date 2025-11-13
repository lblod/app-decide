# DECIDe 

This repository contains all configuration to get the DECIDe microservices stack running. It is very much a work in progress.

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

### Consuming decisions

Decision data from Lokaal Beslist is ingested by a consumer. The initial sync and/or delta ingest should be enabled manually in `docker-compose.override.yml`:

```yml
services:
  lokaal-beslist-consumer:
    environment:
      DCR_DISABLE_INITIAL_SYNC: false
      DCR_DISABLE_DELTA_INGEST: false
```