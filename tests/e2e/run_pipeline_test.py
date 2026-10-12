#!/usr/bin/env python3
"""Run one PDF through the pdf-to-enriched job, one workflow step per stage of the chain.

Usage: run_pipeline_test.py migrations | seed | wait <stage>
"""
from common import (
    JOBS_GRAPH, PUBLIC_GRAPH, STATUS, TASK_OP, ask, job_triples, new_resource, run_cli, sparql)

PDF_URL = "https://www.horebeke.be/src/Frontend/Files/userfiles/files/Notulen%20ocmw%20raad%2024_11_2025.pdf"
MUNICIPALITY = "http://data.lblod.info/id/bestuurseenheden/69af2347b1d0a9a39dbcf0ea4d94b9eaa15edb0c7d2dba56bbd9c39ab1c80e9f"
EXPECTED_LOCATION = "Kerkplein 1"

JOB_OP = "http://lblod.data.gift/id/jobs/concept/JobOperation/harvesting/pdf-to-enriched"
CHAIN = [
    "singleton-job",
    "pdf-scraping",
    "pdf-to-eli",
    "split-task-pdf-to-enriched-translating",
    "translating",
    "segmenting",
    "entity-extracting",
    "named-entity-linking",
]
# One translating task per decision; done when each chain reached linking.
FAN_OUT = ("translating", "named-entity-linking")


def seed():
    remote, remote_id = new_resource("http://lblod.data.gift/id/remote-data-objects/")
    collection, collection_id = new_resource("http://data.lblod.info/id/harvesting-collection/")
    pdf_container, pdf_container_id = new_resource("http://redpencil.data.gift/id/dataContainers/")
    municipality_container, municipality_container_id = new_resource("http://redpencil.data.gift/id/dataContainers/")
    job, triples = job_triples(JOB_OP, [pdf_container, municipality_container], ["ext:splitDecisions true"])
    sparql(f"""
INSERT DATA {{
  GRAPH <{JOBS_GRAPH}> {{{triples}
    <{remote}> a nfo:RemoteDataObject ;
      mu:uuid "{remote_id}" ;
      nie:url <{PDF_URL}> .
    <{collection}> a hrvst:HarvestingCollection ;
      mu:uuid "{collection_id}" ;
      dct:hasPart <{remote}> .
    <{pdf_container}> a nfo:DataContainer ;
      mu:uuid "{pdf_container_id}" ;
      task:hasHarvestingCollection <{collection}> .
    <{municipality_container}> a nfo:DataContainer ;
      mu:uuid "{municipality_container_id}" ;
      task:hasResource <{MUNICIPALITY}> .
  }}
}}""", update=True)
    return {"job": job}


def annotation_by(job, operation, condition):
    return f"""
GRAPH <{JOBS_GRAPH}> {{ ?task dct:isPartOf <{job}> ; task:operation <{TASK_OP}{operation}> . }}
GRAPH <{PUBLIC_GRAPH}> {{
  ?task prov:generated ?annotation .
  ?annotation a oa:Annotation ; oa:hasBody ?statement .
  ?statement rdf:predicate ?predicate ; rdf:object ?object .
}}
FILTER({condition})"""


CHECKS = {
    "pdf-to-eli": {
        "pdf-to-eli created an expression with content": lambda state: ask(f"""
GRAPH <{PUBLIC_GRAPH}> {{
  ?manifestation a eli:Manifestation ; eli:is_exemplified_by <{PDF_URL}> .
  ?expression a eli:Expression ; eli:is_embodied_by ?manifestation ; epvoc:expressionContent ?text .
}}
FILTER(STRLEN(STR(?text)) > 0)"""),
    },
    "translating": {
        "translating created a translated expression": lambda state: ask(f"""
GRAPH <{PUBLIC_GRAPH}> {{
  ?manifestation eli:is_exemplified_by <{PDF_URL}> .
  ?expression eli:is_embodied_by ?manifestation ; gold:translation ?translated .
  ?translated epvoc:expressionContent ?text .
}}
FILTER(STRLEN(STR(?text)) > 0)"""),
    },
    "segmenting": {
        "segmenting wrote a segment annotation": lambda state: ask(annotation_by(
            state["job"], "segmenting",
            'STRSTARTS(STR(?predicate), "http://mu.semte.ch/vocabularies/ext/")')),
    },
    "entity-extracting": {
        f"entity-extracting found the location {EXPECTED_LOCATION}": lambda state: ask(annotation_by(
            state["job"], "entity-extracting",
            f'?predicate = prov:atLocation && EXISTS {{ ?object rdfs:label ?label . '
            f'FILTER(STR(?label) = "{EXPECTED_LOCATION}") }}')),
    },
}


if __name__ == "__main__":
    run_cli(CHAIN, seed, CHECKS, FAN_OUT)
