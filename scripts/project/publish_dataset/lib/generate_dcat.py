from datetime import datetime
from jinja2 import Environment, FileSystemLoader
env = Environment(loader=FileSystemLoader("."))

from helpers import graph_has_subject, turtle_to_insert_data, update, log, delete_linked_resources, delete_reverse_linked_resources
from config import datadump_file_name, dataset_uri_and_uuid, distribution_uri_and_uuid, service_uri_and_uuid, PUBLIC_GRAPH

def step1_write_catalog(organization: str, organization_config: dict, now_iso: str) -> None:
    log("[Step 1] Generate DCAT Catalog for %s", organization)
    catalog_uri = organization_config["catalog_uri"]
    catalog_publisher_uri = organization_config["catalog_publisher"].get("uri")
    catalog_subjects = [catalog_uri] + ([catalog_publisher_uri] if catalog_publisher_uri else [])

    if graph_has_subject(catalog_uri, PUBLIC_GRAPH):
        log("Catalog '%s' already exists in <%s>, doing nothing.", organization, PUBLIC_GRAPH)
    else:
        catalog_template = env.get_template("templates/dcat-catalog.ttl.j2")
        catalog_output = catalog_template.render(
            ISSUED=now_iso,
            MODIFIED=now_iso,
            **organization_config)
        update(turtle_to_insert_data(catalog_output, PUBLIC_GRAPH))
        log("DCAT Catalog '%s' written to <%s>.", organization, PUBLIC_GRAPH)


def step2_write_dataset(organization: str, organization_config: dict, dataset: str, dataset_config: dict, timestamp: str, timestamp_iso: str) -> None:
    log("[Step 2] Generate DCAT Dataset for %s", dataset_config['description'])
    dataset_uuid, dataset_uri = dataset_uri_and_uuid(dataset, dataset_config, organization, organization_config)
    service_uuid, service_uri = service_uri_and_uuid(dataset, dataset_config, organization)
    distribution_uuid, distribution_uri = distribution_uri_and_uuid(dataset, dataset_config, organization, timestamp)

    insert_dataset = True
    insert_dataservice = True
    insert_distribution = True
    if graph_has_subject(dataset_uri, PUBLIC_GRAPH):
        log("DCAT Dataset '%s' already exists in <%s>, only appending link to the service and distribution if they don't exist yet.", dataset, PUBLIC_GRAPH)
        insert_dataset = False
        if graph_has_subject(service_uri, PUBLIC_GRAPH):
            insert_dataservice = False
        if graph_has_subject(distribution_uri, PUBLIC_GRAPH):
            insert_distribution = False

    datadump_base_url = organization_config.get("datadump_base_url")
    output_file_name = dataset_config.get("output_file_name", dataset)
    datadump_url = (
        f"{datadump_base_url.rstrip('/')}/{datadump_file_name(output_file_name, timestamp)}"
        if datadump_base_url else None
    )
    dataset_template = env.get_template("templates/dcat-dataset.ttl.j2")
    dataset_output = dataset_template.render(
        insert_dataset=insert_dataset,
        insert_dataservice=insert_dataservice,
        insert_distribution=insert_distribution,
        ISSUED=timestamp_iso,
        MODIFIED=timestamp_iso,
        dataset=dataset_config,
        dataset_uri=dataset_uri,
        dataset_uuid=dataset_uuid,
        service_uri=service_uri,
        service_uuid=service_uuid,
        distribution_uri=distribution_uri,
        distribution_uuid=distribution_uuid,
        datadump_url=datadump_url,
        **organization_config)

    if insert_distribution:
        delete_linked_resources(dataset_uri, "http://www.w3.org/ns/dcat#distribution", PUBLIC_GRAPH)
    if insert_dataservice:
        delete_reverse_linked_resources(dataset_uri, "http://www.w3.org/ns/dcat#servesDataset", PUBLIC_GRAPH)

    update(turtle_to_insert_data(dataset_output, PUBLIC_GRAPH))
    log("DCAT Dataset '%s' written to <%s>.", dataset, PUBLIC_GRAPH)

def generate_dcat(timestamp: str, dataset: str, dataset_config: dict, organization: str, organization_config: dict) -> None:
    if not organization_config.get("sparql_endpoint"):
        log("  No 'sparql_endpoint' configured for organization '%s', skipping its SPARQL DCAT service.", organization)
    if not organization_config.get("datadump_base_url"):
        log("  No 'datadump_base_url' configured for organization '%s', skipping its data dump distribution.", organization)

    timestamp_iso = datetime.strptime(timestamp, "%Y%m%d%H%M%S").isoformat()

    log("=== Generating DCAT ===")
    log("Processing for '%s' …", organization)

    step1_write_catalog(organization, organization_config, timestamp_iso)
    step2_write_dataset(organization, organization_config, dataset, dataset_config, timestamp, timestamp_iso)

    log("[DCAT Pipeline] Finished. DCAT catalog + dataset written for dataset '%s' (organization: '%s') to <%s>.", dataset, organization, PUBLIC_GRAPH)
