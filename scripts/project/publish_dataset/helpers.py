import logging
import os
import sys

from SPARQLWrapper import JSON, SPARQLWrapper

MU_SPARQL_ENDPOINT = os.environ.get("MU_SPARQL_ENDPOINT", "http://database:8890/sparql")
MU_SPARQL_UPDATEPOINT = os.environ.get("MU_SPARQL_UPDATEPOINT", MU_SPARQL_ENDPOINT)

logger = logging.getLogger("publish_dataset")
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO").upper())
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
