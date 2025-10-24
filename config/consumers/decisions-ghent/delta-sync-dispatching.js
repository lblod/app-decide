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
  }
}
