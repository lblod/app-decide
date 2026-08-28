import logging
import os
import sys
from pathlib import Path
import uuid

from SPARQLWrapper import JSON, SPARQLWrapper
from rdflib import BNode, Literal, URIRef, Graph as RDFGraph
from rdflib.compare import to_canonical_graph
from config import LOG_LEVEL, MU_SPARQL_ENDPOINT, MU_SPARQL_UPDATEPOINT, BASE_URL

logger = logging.getLogger("publish_dataset")
logger.setLevel(LOG_LEVEL)
logger.addHandler(logging.StreamHandler(stream=sys.stdout))

def log(msg, *args, **kwargs):
    """Write a log message. Same signature as logging.Logger.info."""
    return logger.info(msg, *args, **kwargs)


def _client(endpoint: str, return_format: str) -> SPARQLWrapper:
    client = SPARQLWrapper(endpoint, returnFormat=return_format)
    # This script has no session of its own, so bypass the ODRL policy
    # enforced by the sparql-parser service to allow writes (e.g. to the
    # public graph) and reads across graphs it would otherwise have no
    # party/scope to be granted access under.
    client.addCustomHttpHeader("mu-auth-sudo", "true")
    return client


def query(the_query: str):
    """Execute a SELECT/ASK/CONSTRUCT query. Returns the parsed JSON result (dict).

    Note: the sparql-parser service does not honor Accept negotiation and
    always returns sparql-results+json. For CONSTRUCT queries, it represents
    each produced triple as a binding row named after the template's
    variables rather than RDF — build RDF terms client-side from those.
    """
    client = _client(MU_SPARQL_ENDPOINT, JSON)
    client.setQuery(the_query)
    log("Execute query:\n%s", the_query)
    return client.query().convert()


def update(the_query: str) -> None:
    """Execute a SPARQL update (INSERT/DELETE) query."""
    client = _client(MU_SPARQL_UPDATEPOINT, JSON)
    client.setQuery(the_query)
    client.method = "POST"
    log("Execute update:\n%s", the_query)
    client.query()

def paginate_insert(insert_query: str, limit: int, offset: int) -> str:
    # SPARQL Update has no solution modifier on INSERT ... WHERE itself (that's
    # a Virtuoso-only extension); a standard-compliant proxy like sparql-parser
    # rejects trailing LIMIT/OFFSET there. Instead, wrap the WHERE body in a
    # `{ SELECT * WHERE { ... } LIMIT n OFFSET m }` subquery, which is valid
    # SPARQL 1.1 and projects every variable bound inside.
    body = insert_query.rstrip()
    assert body.endswith("}"), "INSERT query must end with the closing WHERE brace }"
    upper = body.upper()
    where_pos = upper.index("WHERE")
    head = body[:where_pos]
    open_brace_pos = body.index("{", where_pos)
    where_inner = body[open_brace_pos + 1:-1]
    return f"{head}WHERE {{\n  SELECT * WHERE {{\n{where_inner}\n  }}\n  LIMIT {limit}\n  OFFSET {offset}\n}}\n"

def term_from_binding(binding: dict):
    value = binding["value"]
    if binding["type"] == "uri":
        return URIRef(value)
    if binding["type"] == "bnode":
        return BNode(value)
    lang = binding.get("xml:lang")
    if lang:
        return Literal(value, lang=lang)
    datatype = binding.get("datatype")
    if datatype:
        return Literal(value, datatype=URIRef(datatype))
    return Literal(value)

def to_wellknown_uri(term, base_uri: str):
    if isinstance(term, BNode):
        return URIRef(f"{base_uri}/.well-known/shacl/{term}")
    return term

def insert_to_count(insert_query: str, interesting_variable: str) -> str:
    upper      = insert_query.upper()
    insert_pos = upper.index("INSERT")
    where_pos  = upper.index("WHERE", insert_pos)
    prefixes   = insert_query[:insert_pos]
    where_body = insert_query[where_pos:].rstrip()
    assert where_body.endswith("}"), "WHERE clause must end with }"
    return prefixes + f"SELECT (COUNT(DISTINCT ?{interesting_variable}) AS ?n) " + where_body + "\n"

def turtle_to_insert_data(turtle: str | Path, graph: str) -> str:
    """Parse Turtle (from a string or a file path) and serialize to N-Triples
    so it can be embedded in a SPARQL INSERT DATA block without dealing with
    prefix declarations."""
    g = RDFGraph()
    if isinstance(turtle, Path) or (isinstance(turtle, str) and os.path.isfile(turtle)):
        g.parse(source=turtle, format="turtle")
    else:
        g.parse(data=turtle, format="turtle")

    # Relabel blank nodes deterministically based on graph structure
    canon = to_canonical_graph(g)

    skolemized = RDFGraph()
    for s, p, o in canon:
        skolemized.add((to_wellknown_uri(s, BASE_URL), p, to_wellknown_uri(o, BASE_URL)))

    ntriples = skolemized.serialize(format="nt")
    return f"INSERT DATA {{ GRAPH <{graph}> {{\n{ntriples}\n}} }}"

def delete_subjects(subjects: list[str], graph: str) -> None:
    """Delete every triple whose subject is one of `subjects`, so a re-render can fully replace them."""
    values = " ".join(f"<{s}>" for s in subjects)
    update(f"""
DELETE {{
  GRAPH <{graph}> {{ ?subject ?p ?o . }}
}}
WHERE {{
  GRAPH <{graph}> {{ ?subject ?p ?o . }}
  VALUES ?subject {{ {values} }}
}}
""")

def select_rows(q: str) -> list[dict]:
    bindings = query(q)["results"]["bindings"]
    return [{k: v["value"] for k, v in row.items()} for row in bindings]


def graph_has_type(subject: str, thing: str, graph: str) -> bool:
    return query(f"ASK {{ GRAPH <{graph}> {{ <{subject}> a <{thing}> . }} }}")["boolean"]


def get_issued(subject: str, graph: str) -> str | None:
    """Return `subject`'s existing dct:issued value, if any, so a re-render can preserve it instead of resetting it."""
    rows = select_rows(f"""
PREFIX dct: <http://purl.org/dc/terms/>
SELECT ?issued WHERE {{ GRAPH <{graph}> {{ <{subject}> dct:issued ?issued . }} }}
""")
    return rows[0]["issued"] if rows else None


def enhance_uris(shapesGraph: RDFGraph, prefix: str, add: str) -> RDFGraph:
    """
    Read a Turtle file, replace any subject/object URI starting with `prefix` with a new URI of the form `prefix` + `/` + `add`
    """
    new_g = RDFGraph()
    # preserve any bound namespace prefixes
    for pfx, ns in shapesGraph.namespaces():
        new_g.bind(pfx, ns)

    for s, p, o in shapesGraph:
        new_s = s
        new_o = o
        if isinstance(s, URIRef) and str(s).startswith(prefix):
            new_s = URIRef(f"{str(s)}/{add}")
        if isinstance(o, URIRef) and str(o).startswith(prefix):
            new_o = URIRef(f"{str(o)}/{add}")
        new_g.add((new_s, p, new_o))

    return new_g

def delete_linked_resources(subject: str, predicate: str, graph: str) -> None:
    """Delete linked resources of a given subject and predicate, e.g. to remove a previous distribution or service from a dataset before inserting a new one."""
    update(f"""
        PREFIX dcat: <http://www.w3.org/ns/dcat#>
        DELETE {{
        GRAPH <{graph}> {{ 
            <{subject}> <{predicate}> ?object .
            ?object ?p ?o .
        }}
        }}
        WHERE {{
        GRAPH <{graph}> {{ 
            <{subject}> <{predicate}> ?object .
            OPTIONAL {{
                ?object ?p ?o .
            }}
        }}
        }}
    """)

def delete_reverse_linked_resources(subject: str, predicate: str, graph: str) -> None:
    """Delete linked resources of a given subject and predicate, e.g. to remove a previous distribution or service from a dataset before inserting a new one."""
    update(f"""
        PREFIX dcat: <http://www.w3.org/ns/dcat#>
        DELETE {{
        GRAPH <{graph}> {{ 
            ?object <{predicate}> <{subject}> .
            ?object ?p ?o .
        }}
        }}
        WHERE {{
        GRAPH <{graph}> {{ 
            ?object <{predicate}> <{subject}> .
            OPTIONAL {{
                ?object ?p ?o .
            }}
        }}
        }}
    """)