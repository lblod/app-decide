import subprocess

from pathlib import Path
import uuid
from rdflib import BNode, URIRef, Graph as RDFGraph
from rdflib.collection import Collection
from rdflib.compare import to_canonical_graph
from rdflib.namespace import DCAT, DCTERMS, RDF, SH, OWL
from helpers import delete_linked_resources, enhance_uris, to_wellknown_uri, turtle_to_insert_data, update, log
from config import datadump_file_name, shacl_file_name, shacl_adapted_file_name, landing_page_file_name, dataset_uri_and_uuid, BASE_URL, OUTPUT_DIR, PUBLIC_GRAPH, SHAPES_BASE_URL

def _run_shacl_play(args: list[str], description: str) -> None:
    """Run a shacl-play CLI command, failing loudly instead of letting
    downstream steps silently work on stale/partial output."""
    result = subprocess.run(
        ["java", "-jar", "/opt/shacl-play.jar", *args],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        log("shacl-play failed (%s):\n%s", description, result.stderr)
        raise RuntimeError(f"shacl-play failed: {description}")

def _step1_generate_shapes(dataset: str, dataset_uuid: str, output_file_name: str, timestamp: str) -> Path:
    datadump_output_file = OUTPUT_DIR / datadump_file_name(output_file_name, timestamp)
    shacl_output_file = OUTPUT_DIR / shacl_file_name(output_file_name, timestamp)
    _run_shacl_play(
        ["generate", "--input", str(datadump_output_file), "--output", str(shacl_output_file), 
            "--prefix", "ext:http://mu.semte.ch/vocabularies/ext/",
            "--prefix", "dcat:http://www.w3.org/ns/dcat#",
            "--prefix", "dct:http://purl.org/dc/terms/",
            "--prefix", "foaf:http://xmlns.com/foaf/0.1",
            "--prefix", "prov:http://www.w3.org/ns/prov#",
            "--prefix", "skos:http://www.w3.org/2004/02/skos/core#",
            "--prefix", "org:http://www.w3.org/ns/org#",
            "--prefix", "eli:http://data.europa.eu/eli/ontology#",
            "--prefix", "oa:http://www.w3.org/ns/oa#",
            "--prefix", "sh:http://www.w3.org/ns/shacl#",
            "--prefix", "rdf:http://www.w3.org/1999/02/22-rdf-syntax-ns#",
            "--prefix", "rdfs:http://www.w3.org/2000/01/rdf-schema#",
            "--prefix", "xsd:http://www.w3.org/2001/XMLSchema#",
            "--prefix", "mu:http://mu.semte.ch/vocabularies/core/",
            "--prefix", "geo:http://www.opengis.net/ont/geosparql#",
            "--prefix", "vcard:http://www.w3.org/2006/vcard/ns#",
            "--prefix", "schema:http://schema.org/",
            "--prefix", "locn:http://www.w3.org/ns/locn#",
            "--prefix", "nif:http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#"
        ],
        description=f"generate shapes for dataset '{dataset}'",
    )
    log("SHACL Shapes for DCAT Dataset '%s' generated", dataset)
    return shacl_output_file

def _step2_adapt_shapes_and_link_with_dataset(
    dataset: str, dataset_config: dict, organization: str, organization_config: dict, timestamp: str, output_file_name: str, shacl_output_file: Path,
) -> Path:
    dataset_uuid, dataset_uri = dataset_uri_and_uuid(dataset, dataset_config, organization, organization_config)
    shapes_graph = RDFGraph()
    shapes_graph.parse(source=shacl_output_file, format="turtle")

    # Make shape URIs specific to the dataset, otherwise overlap possible with other datasets
    new_shapes_graph = enhance_uris(shapes_graph, SHAPES_BASE_URL, dataset_uuid)

    # Remove any owl:Ontology triples, as abundant
    new_shapes_graph.remove((None, RDF.type, OWL.Ontology))

    # Retrieve all SHACL NodeShapes from the new shapes graph, to combine them under a single NodeShape wrapper via sh:or
    wrapper_shape_uri = URIRef(f"{BASE_URL}/id/shapes/{dataset_uuid}")
    node_shapes = sorted(new_shapes_graph.subjects(RDF.type, SH.NodeShape), key=str)
    if node_shapes:
        or_list_node = BNode()
        Collection(new_shapes_graph, or_list_node, node_shapes)
        new_shapes_graph.add((wrapper_shape_uri, SH["or"], or_list_node))

    new_shapes_graph.add((wrapper_shape_uri, RDF.type, SH.NodeShape))

    # Add a dct:conformsTo triple to the dataset, pointing to the wrapper shape
    new_shapes_graph.add((dataset_uri, DCTERMS.conformsTo, wrapper_shape_uri))

    # Relabel blank nodes deterministically based on graph structure, otherwise every run with same dataset configuration will produce distinct skolem identifiers
    canon = to_canonical_graph(new_shapes_graph)
    skolemized = RDFGraph()
    for s, p, o in canon:
        skolemized.add((to_wellknown_uri(s, BASE_URL), p, to_wellknown_uri(o, BASE_URL)))

    shacl_adapted_output_file = OUTPUT_DIR / shacl_adapted_file_name(output_file_name, timestamp)
    skolemized.serialize(destination=shacl_adapted_output_file, format="turtle")

    update(turtle_to_insert_data(skolemized.serialize(format="turtle"), PUBLIC_GRAPH))
    log(
        "ConformsTo link for DCAT Dataset '%s' written to <%s>, combining %d shape(s) via sh:or under <%s>.",
        dataset, PUBLIC_GRAPH, len(node_shapes), wrapper_shape_uri,
    )
    return shacl_adapted_output_file

def _step3_generate_landing_page(
    dataset: str, output_file_name: str, timestamp: str, shacl_output_file: Path
) -> Path:
    landing_page_output_file = OUTPUT_DIR / landing_page_file_name(output_file_name, timestamp)
    _run_shacl_play(
        ["doc", "--diagram", "--language", "en", "--input", str(shacl_output_file), "--output", str(landing_page_output_file)],
        description=f"generate documentation for dataset '{dataset}'",
    )
    return landing_page_output_file

def _step4_write_dataset_landing_page(
    dataset: str, dataset_config: dict, organization: str, organization_config: dict, landing_page_output_file: Path
) -> None:
    datadump_base_url = organization_config.get("datadump_base_url")
    if not datadump_base_url:
        log("No 'datadump_base_url' configured for organization '%s', skipping writing its DCAT landing page.", organization)
        return

    landing_page_url = f"{datadump_base_url.rstrip('/')}/{landing_page_output_file.name}"
    dataset_uuid, dataset_uri = dataset_uri_and_uuid(dataset, dataset_config, organization, organization_config)

    delete_linked_resources(dataset_uri, "http://www.w3.org/ns/dcat#landingPage", PUBLIC_GRAPH)

    g = RDFGraph()
    g.add((dataset_uri, DCAT.landingPage, URIRef(landing_page_url)))
    update(turtle_to_insert_data(g.serialize(format="turtle"), PUBLIC_GRAPH))
    log("Landing page for DCAT Dataset '%s' written to '%s'.", dataset, landing_page_url)

def generate_shacl(
    timestamp: str, dataset: str, dataset_config: dict, organization: str, organization_config: dict,
) -> None:
    log("=== Generating SHACL ===")
    log("Processing for '%s' …", organization)

    output_file_name = dataset_config.get("output_file_name", dataset)
    dataset_uuid, dataset_uri = dataset_uri_and_uuid(dataset, dataset_config, organization, organization_config)

    shacl_output_file = _step1_generate_shapes(dataset, dataset_uuid, output_file_name, timestamp)

    shacl_adapted_output_file =_step2_adapt_shapes_and_link_with_dataset(dataset, dataset_config, organization, organization_config, timestamp, output_file_name, shacl_output_file)

    landing_page_output_file = _step3_generate_landing_page(dataset, output_file_name, timestamp, shacl_adapted_output_file)

    _step4_write_dataset_landing_page(dataset, dataset_config, organization, organization_config, landing_page_output_file)

    log("[SHACL Pipeline] Finished. SHACL shapes written for dataset '%s' (organization: '%s') to <%s>.", dataset, organization, PUBLIC_GRAPH)