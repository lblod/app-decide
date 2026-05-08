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


### Outsource LLM to the cloud
The AI services relying on LLMs by default use local models. But they can also be configured to outsource such computations to external services in the cloud. The READMEs for each individual service describe in more detail how to configure them as such. Note that this requires obtaining appropriate API keys for each service.

- The  [named-entity-recognition (NER)](https://github.com/semantic-ai/decide-geocoding-service/blob/master/README.md#L39) service allows to configure providers for several of its features.
- The [entity-linking-backend](https://github.com/semantic-ai/entity-linking-backend/blob/master/README.md) service README documents how to configure external providers.
- The [codelist-labeling](https://github.com/semantic-ai/codelist-labeling-service/blob/master/README.md) service can be configured to use a mistral as external provider. Using another external provider requires adding the appropriate `langchain-*` package to the service by editing its `requirements.txt` file and building your own image.
- The [Question-answering](https://github.com/semantic-ai/decide-question-answering/blob/master/README.md) service can be configured to use different providers. This does require adding the appropriate `langchain-*` package to the service by editing its `requirements.txt` file and building your own image.
- The [Embedding](https://github.com/semantic-ai/embedding-service/blob/master/README.md) service currently does not **not** support using an external provider. Embeddings can generated locally without a GPU, but this will take considerable longer.


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
The city of Bamberg is mostly interested in use case 0.1 and 2. Therefore their [partner-specific configuration](./docker-compose.override.bamberg.yml) disables unnecessary services as well as provide some placeholders for configuring specific services. See the comments in the override file for more information.

#### Data harvesting
Due to technical limitations our `pdf-scraper` service cannot directly retrieve PDFs from the [web portal](https://www.stadt.bamberg.de/buergerinformationssystem/tr010) of the city of Bamberg. A workaround is to obtain the PDFs via another method and feed them into the app from disk using an additional service.

To this end, an `internal-files` service is configured in `docker-compose.override.bamberg.yml`. This service mounts a folder `data/internal-files`, make sure to create this folder, in which PDFs can be placed.

In the pipeline dashboard you can use `http://internal-files/FILENAME.pdf` as input decision URLs. As municipality select `Stadt Bamberg` from the options in the dropdown, as illustrated in the following screenshot.

![Example form for harvesting PDFs](./harvest-bamberg-form-example.png)


### Freiburg
TODO


### Ghent
TODO
