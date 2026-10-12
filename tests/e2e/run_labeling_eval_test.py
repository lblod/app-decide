#!/usr/bin/env python3
"""Run a few decisions through the codelist-matching/evaluation job, one workflow step per stage.

Usage: run_labeling_eval_test.py migrations | seed | wait <stage>
"""
from common import JOBS_GRAPH, PUBLIC_GRAPH, ask, job_triples, new_resource, run_cli, sparql

JOB_OP = "http://lblod.data.gift/id/jobs/concept/JobOperation/codelist-matching/evaluation"
CHAIN = [
    "singleton-job",
    "codelist-matching/evaluation-split-tasks",
    "codelist-matching/annotate",
    "codelist-matching/assess-impact",
]
# One annotate task per split batch; done when each batch reached impact assessment.
FAN_OUT = ("codelist-matching/annotate", "codelist-matching/assess-impact")

CODELIST = "http://lblod.data.gift/id/conceptscheme/sdg-simple"
CODELIST_GRAPH = "http://mu.semte.ch/graphs/public"
NO_MATCH = "http://mu.semte.ch/vocabularies/ext/no-match-found"
IMPACT_PREFIX = "http://mu.semte.ch/vocabularies/ext/impact/"

# The first two clearly relate to a Sustainable Development Goal; the third does not.
DECISIONS = {
    "solar": "The municipal council decides to install solar panels on the roofs of the sports hall "
             "and the library. The panels will cover part of the electricity use of these buildings "
             "with renewable energy and lower the energy costs of the municipality.",
    "meals": "The municipal council approves a subsidy so that children from low-income families "
             "receive a free warm meal every school day in the municipal primary schools.",
    "minutes": "The municipal council approves the minutes of the previous meeting and renames the "
               "committee for general affairs to the committee for internal affairs.",
}
MATCHABLE = ["solar", "meals"]


def seed():
    container, container_id = new_resource("http://redpencil.data.gift/id/dataContainers/")
    shape, shape_id = new_resource("http://data.lblod.info/id/shapes/")
    expressions = {}
    decisions = []
    for key, text in DECISIONS.items():
        expression, expression_id = new_resource("http://data.lblod.info/id/expressions/")
        work, work_id = new_resource("http://data.lblod.info/id/works/")
        expressions[key] = expression
        decisions.append(f"""
    <{work}> a eli:Work ;
      mu:uuid "{work_id}" ;
      eli:is_realized_by <{expression}> .
    <{expression}> a eli:Expression ;
      mu:uuid "{expression_id}" ;
      epvoc:expressionContent "{text}" .""")
    resources = ", ".join(f"<{expression}>" for expression in expressions.values())
    job, triples = job_triples(JOB_OP, [container], [
        f"ext:codelist <{CODELIST}>", f"ext:shapeForTargets <{shape}>", f"ext:graphForTargets <{PUBLIC_GRAPH}>"])
    sparql(f"""
INSERT DATA {{
  GRAPH <{PUBLIC_GRAPH}> {{{"".join(decisions)}
  }}
  GRAPH <{JOBS_GRAPH}> {{{triples}
    <{shape}> a sh:NodeShape ;
      mu:uuid "{shape_id}" ;
      sh:targetNode {resources} .
    <{container}> a nfo:DataContainer ;
      mu:uuid "{container_id}" ;
      task:hasResource <{shape}> .
  }}
}}""", update=True)
    return {"job": job, "expressions": expressions}


def classifying(expression, body_condition):
    return f"""
GRAPH <{PUBLIC_GRAPH}> {{
  ?annotation a oa:Annotation ;
    oa:motivatedBy oa:classifying ;
    oa:hasTarget <{expression}> ;
    oa:hasBody ?body .
}}
FILTER({body_condition})"""


def in_codelist(expression):
    return f"""
GRAPH <{PUBLIC_GRAPH}> {{
  ?annotation a oa:Annotation ;
    oa:motivatedBy oa:classifying ;
    oa:hasTarget <{expression}> ;
    oa:hasBody ?body .
}}
GRAPH <{CODELIST_GRAPH}> {{ ?body skos:inScheme <{CODELIST}> . }}"""


def labeled(key):
    return lambda state: ask(classifying(
        state["expressions"][key],
        f'?body = <{NO_MATCH}> || EXISTS {{ GRAPH <{CODELIST_GRAPH}> {{ ?body skos:inScheme <{CODELIST}> }} }}'))


def matched_any(state):
    return ask(" UNION ".join(f"{{ {in_codelist(state['expressions'][key])} }}" for key in MATCHABLE))


def impact_added(state):
    return ask(f"""
GRAPH <{PUBLIC_GRAPH}> {{
  ?annotation a oa:Annotation ;
    oa:motivatedBy oa:classifying ;
    oa:hasTarget ?expression ;
    oa:hasBody ?impact .
}}
FILTER(STRSTARTS(STR(?impact), "{IMPACT_PREFIX}"))""")


CHECKS = {
    "codelist-matching/annotate": {
        **{f"annotate labeled the {key} decision (a concept or no-match)": labeled(key) for key in DECISIONS},
        "annotate matched a codelist concept for at least one SDG-related decision": matched_any,
    },
    "codelist-matching/assess-impact": {
        "assess-impact added an impact to a matched annotation": impact_added,
    },
}


if __name__ == "__main__":
    run_cli(CHAIN, seed, CHECKS, FAN_OUT)
