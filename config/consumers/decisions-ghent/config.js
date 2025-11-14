export const INGEST_GRAPH =
  process.env.INGEST_GRAPH || `http://mu.semte.ch/graphs/public`;
export const FILTERED_GRAPH =
  process.env.FILTERED_GRAPH || `http://mu.semte.ch/graphs/filtered`;

export const BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES =
  process.env.BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES == "true" ? true : false;
export const DIRECT_DATABASE_ENDPOINT =
  process.env.DIRECT_DATABASE_ENDPOINT || "http://virtuoso:8890/sparql";
export const MU_SPARQL_ENDPOINT =
  process.env.MU_SPARQL_ENDPOINT || "http://database:8890/sparql";
export const sparqlEndpoint = BYPASS_MU_AUTH_FOR_EXPENSIVE_QUERIES
  ? DIRECT_DATABASE_ENDPOINT
  : MU_SPARQL_ENDPOINT;

export const MU_CALL_SCOPE_ID_INITIAL_SYNC =
  process.env.MU_CALL_SCOPE_ID_INITIAL_SYNC ||
  "http://redpencil.data.gift/id/concept/muScope/deltas/consumer/initialSync/decisions-ghent";
