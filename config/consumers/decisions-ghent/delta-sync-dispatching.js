/**
 * Dispatch the fetched information to a target graph.
 * @param { mu, muAuthSudo, fetch } lib - The provided libraries from the host service.
 * @param { termObjectChangeSets: { deletes, inserts } } data - The fetched changes sets, which objects of serialized Terms
 *          [ {
 *              graph: "<http://foo>",
 *              subject: "<http://bar>",
 *              predicate: "<http://baz>",
 *              object: "<http://boom>^^<http://datatype>"
 *            }
 *         ]
 * @return {void} Nothing
 */
export async function dispatch(lib, data) {
  const { mu, muAuthSudo } = lib;
  const { termObjectChangeSets } = data;

  console.log(`Found an amount of ${termObjectChangeSets.length} changesets`);
  for (let { deletes, inserts } of termObjectChangeSets) {
    console.log(`Logging delete information: `);
    const deleteStatements = deletes.map(
      (o) =>
        `In graph: ${o.graph}, triple: ${o.subject} ${o.predicate} ${o.object}`
    );
    deleteStatements.forEach((s) => console.log(s));

    console.log(`Logging insert information: `);
    const insertStatements = inserts.map(
      (o) =>
        `In graph: ${o.graph}, triple: ${o.subject} ${o.predicate} ${o.object}.`
    );
    insertStatements.forEach((s) => console.log(s));
  }
  console.log(`All changeSets were logged, waiting for next update!`);
}
