import {
  INGEST_GRAPH,
  BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES,
  sparqlEndpoint,
} from "./config";

export async function dispatch(lib, data) {
  const { insertIntoGraph, deleteFromGraph } = lib;
  const { termObjectChangeSets } = data;

  for (let { deletes, inserts } of termObjectChangeSets) {
    if (BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES) {
      console.warn(`Service configured to skip MU_AUTH!`);
    }
    console.log(`Using ${sparqlEndpoint} to insert triples`);

    await deleteFromGraph(deletes, sparqlEndpoint, INGEST_GRAPH, {});
    await insertIntoGraph(inserts, sparqlEndpoint, INGEST_GRAPH, {});

    // -- FILTERED GRAPH --

    // DELETE: just delete from filtered graph

    // INSERT:

    // Necessities:
    // - list of unique properties
    // - list of unique types (incl. rdf:type and mu:uuid)
    // - property path to bestuursorgaan for each type

    // Steps:
    // 1) check whether insert property is in list of properties
    // 2) query subject's type from ingest graph
    // 3) check whether suject's type is in list of types
    // 4) query ingest graph whether subject belongs to bestuursorgaan (use property path)
    // 5) if all checks succeed, insert into filtered graph

    // Create task:
    // - new task:Task
    // - task:operation: <http://lblod.data.gift/id/jobs/concept/TaskOperation/mapping/sparql-construct>
    // - adms:status: <http://redpencil.data.gift/id/concept/JobStatus/scheduled>
    // - task:inputContainer: with ext:hasResource pointing to insert's subject
  }
}
