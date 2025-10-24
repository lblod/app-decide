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

### Consuming

> These steps only need to happen on the application's first run.

The app consumes Ghent decisions from Lokaal Beslist. By default, both initial sync and delta ingest are disabled. These are the steps to correctly consume data.

1. Enable initial sync in `docker-compose.override.yml`:
```yml
services:
  decisions-ghent-consumer:
    environment:
      BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES: true # Only on first run
      DCR_DISABLE_INITIAL_SYNC: false # Only on first run
```

2. Run the consumer:
```bash
docker compose up -d virtuoso database decisions-ghent-consumer
```

3. Wait for the initial sync to finish.

4. Enable delta ingest in `docker-compose.override.yml`:
```yml
services:
  decisions-ghent-consumer:
    environment:
      DCR_DISABLE_DELTA_INGEST: false
```

Keep things like this to make sure Ghent decisions stay up to date throughout the lifetime of the application. The stack can now be run properly.

> Ghent decisions can found in the `http://mu.semte.ch/graphs/decisions/ghent` graph, while all the original Lokaal Beslist data (all decisions) can be found in the `http://mu.semte.ch/graphs/decisions/landing` graph.


### Running the stack

This should be your go-to way of starting the stack.

```bash
docker compose up -d # run without -d flag when you don't want to run it in the background
```