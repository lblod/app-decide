# Additional documentation

This folder contains additional documentation, primarily aimed at configuring and setting up the application to support only a subset of the use cases.


## Server setup
### Requirements
#### Hardware
To run the full app a sufficiently powerful server is advised. A GPU is only required if you want to locally run the LLM-based functionality. Otherwise, the relevant services should be configured to outsource such functionality to cloud services.

Our server has the following specifications:

- CPU: 13th Gen Intel(R) Core(TM) i5-13500
- GPU: NVIDIA RTX 4000 SFF Ada Generation
- Memory: 64GB
- Storage: 2TB

#### Software
This application is a [semantic.works](https://semantic.works/) app and thereby has limited dependencies. The following software is required to run the application:

- `git` to obtain the application source code
- `docker` and `docker compose` to configure and run the application's microservices
- A reverse proxy that forwards HTTP requests to the app's identifier service. We typically use [app-letsencrypt](https://github.com/redpencilio/app-letsencrypt) for this purpose.

### Updating the app
Generally updating (parts of) the app consists of pulling the latest version from the remote repository via a  `git pull` and, recreating and/or restarting the appropriate services.
For each service `A` that was added or updated (version bump or changed environment variables), do `docker compose up [-d] A`. For each service `B` for which their configuration was updated in the `../config/B` folder, do a `docker compose restart B`. Note, that `up` on its own does **not** cause a service to update its configuration.


## Service configuration
TODO

### Identifier
TODO: identifier (cf. `docker-compose.override.yml` on TEST/DEV)
- Environment variables
- networks

### Subdomains used for different frontends
TODO: note about dispatcher and subdomains
- point to dispatcher config + rules involving `reverse_host`
- list frontend and expected subdomain

### Pipeline dashboard
TODO: better authentication credentials for harvester frontend (example migration)
[Migration](config/migrations/add-test-user/20251211000000-add-test-user.sparql)

### Verifiable credentials
- TODO VC configuration


## Partner configurations
This folder also contains some pre-configured docker compose configurations disabling services that are unnecessary for the use cases specific partners are interested in. The easiest way to include this configurations is to add them as last entry in your `.env` file:

```bash
COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml:./docs/docker-compose.override.NAME.yml
```

Note, take care **not** to include the `docker-compose.dev.yml` file here as this can expose services to the outside world.


### Bamberg
- TODO PDFs via file service (cf. issue with session link and PDF download link)


### Freiburg
TODO


### Ghent
TODO
