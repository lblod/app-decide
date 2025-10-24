import {
  INGEST_GRAPH,
  BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES,
  MU_CALL_SCOPE_ID_INITIAL_SYNC,
  sparqlEndpoint,
} from "./config";

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

export async function onFinishInitialIngest(_lib) {
  console.log(`
    onFinishInitialIngest was called!
    Current implementation does nothing, no worries.
    You can overrule it for extra manipulations after initial ingest.
  `);
}
