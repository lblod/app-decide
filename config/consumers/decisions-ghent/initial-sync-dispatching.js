/* Variables */
const INGEST_GRAPH =
  process.env.INGEST_GRAPH || `http://mu.semte.ch/graphs/public`;

const BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES =
  process.env.BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES == "true" ? true : false;
const DIRECT_DATABASE_ENDPOINT =
  process.env.DIRECT_DATABASE_ENDPOINT || "http://virtuoso:8890/sparql";

const MU_CALL_SCOPE_ID_INITIAL_SYNC =
  process.env.MU_CALL_SCOPE_ID_INITIAL_SYNC ||
  "http://redpencil.data.gift/id/concept/muScope/deltas/consumer/initialSync";

const sparqlEndpoint = BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES
  ? DIRECT_DATABASE_ENDPOINT
  : process.env.MU_SPARQL_ENDPOINT;

/** Code **/
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
