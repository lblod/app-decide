/* Variables */
const INGEST_GRAPH =
  process.env.INGEST_GRAPH || `http://mu.semte.ch/graphs/public`;

const BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES =
  process.env.BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES == "true" ? true : false;
const DIRECT_DATABASE_ENDPOINT =
  process.env.DIRECT_DATABASE_ENDPOINT || "http://virtuoso:8890/sparql";

const sparqlEndpoint = BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES
  ? DIRECT_DATABASE_ENDPOINT
  : process.env.MU_SPARQL_ENDPOINT; //Defaults to mu-auth

/* Codes */
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
