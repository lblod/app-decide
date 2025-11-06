import {
  INGEST_GRAPH,
  FILTERED_GRAPH,
  BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES,
  MU_CALL_SCOPE_ID_INITIAL_SYNC,
  sparqlEndpoint,
} from "./config";

import { queries } from "./queries";

export async function dispatch(lib, data) {
  const { insertIntoGraph } = lib;

  if (BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES) {
    console.warn(`Service configured to skip MU_AUTH!`);
  }
  console.log(`Using ${sparqlEndpoint} to insert triples`);

  await insertIntoGraph(data.termObjects, sparqlEndpoint, INGEST_GRAPH, {
    "mu-call-scope-id": MU_CALL_SCOPE_ID_INITIAL_SYNC,
  });
}

export async function onFinishInitialIngest(lib) {
  // For each query in queries:
  // 1) Run on INGEST_GRAPH
  // 2) Insert results in FILTERED_GRAPH
}
