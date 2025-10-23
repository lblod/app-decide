/**
 * Dispatch the fetched information to a target graph.
 * @param { mu, muAuthSudo, fetch, chunk, sparqlEscapeUri, prepareStatements, updateWithRecover } lib - The provided libraries from the host service.
 * @param { termObjects } data - The fetched quad information, which objects of serialized Terms
 *          [ {
 *              graph: "<http://foo>",
 *              subject: "<http://bar>",
 *              predicate: "<http://baz>",
 *              object: "<http://boom>^^<http://datatype>"
 *            }
 *         ]
 * @param { LANDING_ZONE_GRAPH, LANDING_ZONE_DATABASE_ENDPOINT } env - Environment variables
 * @return {void} Nothing
 */
export async function dispatch(lib, data, env) {
  const { updateWithRecover, prepareStatements } = lib;
  const { LANDING_ZONE_GRAPH, LANDING_ZONE_DATABASE_ENDPOINT } = env;

  const triples = data.termObjects || [];
  if (!triples.length) return;

  // Compress URIs using prepareStatements
  const { usedPrefixes, newStmts } = prepareStatements(triples);

  // Transform function for updateWithRecover
  const buildInsertQuery = (stmts) => `
    ${usedPrefixes}
    INSERT DATA {
      GRAPH <${LANDING_ZONE_GRAPH}> {
        ${stmts
          .map(
            ({ subject, predicate, object }) =>
              `${subject} ${predicate} ${object} .`
          )
          .join("\n        ")}
      }
    }
  `;

  console.log(
    `Inserting ${triples.length} triples into ${LANDING_ZONE_GRAPH} ...`
  );

  try {
    await updateWithRecover(
      newStmts,
      buildInsertQuery,
      LANDING_ZONE_DATABASE_ENDPOINT
    );
    console.log(
      `Successfully inserted ${triples.length} triples into ${LANDING_ZONE_GRAPH}`
    );
  } catch (e) {
    console.error(
      `Failed to insert ${triples.length} triples into ${LANDING_ZONE_GRAPH}:`,
      e
    );
  }
}

/**
 * A callback you can override to do extra manipulations
 *   after initial ingest.
 * @param { mu, muAuthSudo, fech } lib - The provided libraries from the host service.
 * @return {void} Nothing
 */
export async function onFinishInitialIngest(lib) {
  console.log(`
    Current implementation does nothing.
  `);
}
