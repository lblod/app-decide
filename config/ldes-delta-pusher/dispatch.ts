import { Changeset, Quad } from '../types';
import { moveTriples } from '../support';
import { sparqlEscapeUri } from 'mu';
import { querySudo as query } from '@lblod/mu-auth-sudo';
import {
  getFilter,
  getGraphFilter,
  streams,
  PUBLIC_GRAPH_FILTER,
} from './config';

type interestingSubject = { subject: string; type: string };

export default async function dispatch(changesets: Changeset[]) {
  // TODO: support for multiple streams will be added later on.
  const publicStream = 'public';

  const insertedSubjects = extractInsertedSubjects(changesets);
  const interestingSubjects = await filterInterestingSubjects(
    insertedSubjects,
    publicStream,
  );
  const inserts = await subjectsToQuads(interestingSubjects, publicStream);

  await moveTriples([
    {
      inserts: inserts,
      deletes: [],
    },
  ]);
}

/**
 * Extract the inserted subjects from the inserts in the given changesets.  This
 * only filters out duplicate subjects.
 * @param {Changeset[]} changesets - The changesets received in the delta
 *   message.
 * @return {string[]} An array of URIs of the subject resources.
 */
function extractInsertedSubjects(changesets: Changeset[]): string[] {
  // NOTE (28/05/2026): Avoid additional filtering of inserts here.  The healing
  // functionality also uses this by sending somewhat fake changesets to the
  // `dispatch` function.  See https://github.com/redpencilio/ldes-delta-pusher-service/blob/f0b272e4cda9bbcef69547d7073ff6b8710e4701/self-healing/heal-ldes-data.ts#L19-L55
  let insertedSubjects = changesets
    .flatMap((changeset) => changeset.inserts)
    .flatMap((quad) => quad.subject.value);

  return [...new Set(insertedSubjects)];
}

/**
 * Filter a set of subjects to those that possibly relevant for the stream.  A
 * subject is considered interesting if it has an RDF resource type that is
 * configured in `streams`.
 * @param {string[]} subjects - The subject URIs to filter.
 * @param {string} stream - The name of a stream as defined in `streams`.
 * @return {Promise<interestingSubject[]>} An array that contains a subset of
 *   interesting subjects enriched with the RDF resource type of the subject.
 */
async function filterInterestingSubjects(
  subjects: string[],
  stream: string,
): Promise<interestingSubject[]> {
  const interestingSubjects: interestingSubject[] = [];

  for (const subject of subjects) {
    const interestingType = await hasInterestingType(subject, stream);
    if (interestingType) {
      interestingSubjects.push({ subject, type: interestingType });
    }
  }

  return interestingSubjects;
}

/**
 * Returns an RDF type URI if subject is interesting for the LDES feed.  A
 * subject is interesting if it has an RDF type that is listed in `streams` and
 * is found in the graph determined by `PUBLIC_GRAPH_FILTER`.  Note, to keep the
 * query simple, any `filter`s for a type are NOT taken into account.  So this
 * function may return types for a subject that will be filtered out later.  It
 * is up to subsequent functions to handle this situation.
 * @param {string} subject - The URI of the resource to check.
 * @param {string} stream - The name of a stream as defined in `streams`.
 * @return {Promise<string|undefined} The URI of the subject's type if it is
 *   interesting, undefined otherwise.
 */
async function hasInterestingType(
  subject: string,
  stream: string,
): Promise<string | undefined> {
  // NOTE (21/05/2026): For simplicity this query only returns a single type,
  // whichever type the triplestore decides to answer.  This might cause
  // problems if a subject has multiple interesting types.  Since this is
  // currently not the case we ignore the complexity of dealing with that.
  const interestingType = await query(`
    SELECT ?type
    WHERE {
      GRAPH ?g {
        VALUES ?type {
          ${Object.keys(streams[stream])
            .map((type) => sparqlEscapeUri(type))
            .join('\n')}
        }
        ${sparqlEscapeUri(subject)} a ?type .
      }
      ${PUBLIC_GRAPH_FILTER}
    } LIMIT 1`);

  const type = interestingType.results?.bindings[0]?.type?.value;

  if (type) {
    console.info(
      `>>>> INFO: Found interesting type ${type} for subject ${subject} in stream ${stream}`,
    );
  } else {
    console.info(
      `>>>> INFO: Found no interesting type for subject ${subject} in stream ${stream}`,
    );
  }

  return interestingType.results?.bindings[0]?.type?.value;
}

/**
 * Convert the subjects to their corresponding quads.  The quads are retrieved
 * from the triplestore taking the filters configured for that subject in
 * `streams`.
 * @param {interestingSubject[]} subjects - The URIs of the resources and their
 *   RDF types to convert.
 * @return {Promise<Quad[]>} An array containing the quads retrieved for the
 *   provided subjects.
 */
async function subjectsToQuads(
  subjects: interestingSubject[],
  stream: string,
): Promise<Quad[]> {
  const quads = (
    await Promise.all(
      subjects.flatMap(
        async (subject) => await getQuadsForSubject(subject, stream),
      ),
    )
  ).flat();

  return quads;
}

/**
 * Retrieve the relevant quads for the provided subject.  This retrieves all
 * quads for the given subject taken into account the appropriate filters as
 * configured in `streams`.
 * @param {interestingSubject} subject - The URIs of the resources and their RDF
 *   types for which to retrieve the quads.
 * @param {string} stream - The name of a stream as defined in `streams`.
 * @return {Promise<Quad[]>} An array containing all quads for the subject.
 */
async function getQuadsForSubject(
  subject: interestingSubject,
  stream: string,
): Promise<Quad[]> {
  const graphFilter = getGraphFilter(stream, subject.type) ?? '';
  const filter = getFilter(stream, subject.type) ?? '';

  const triples = await query(`
    SELECT DISTINCT ?s ?p ?o
    WHERE {
      ${graphFilter}
      GRAPH ?g {
        VALUES ?s {
          ${sparqlEscapeUri(subject.subject)}
        }
        ?s ?p ?o .
      }
      ${filter}
    }`);

  const quads = bindingsToQuads(triples.results?.bindings);

  console.info(
    `>>> INFO: Found ${quads.length} triples for subject ${subject.subject} of type ${subject.type}`,
  );

  return quads;
}

function bindingsToQuads(bindings) {
  if (bindings?.length > 0) {
    return bindings.map((triple) => {
      return { subject: triple.s, predicate: triple.p, object: triple.o };
    });
  } else {
    return [];
  }
}
