export default [
  {
    currentOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/codelist-matching/training-split-tasks',
    nextOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/codelist-matching/annotate',
  },
  {
    currentOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/codelist-matching/evaluation-split-tasks',
    nextOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/codelist-matching/annotate',
    resourceLimit: 1000,
    resourceFilter: `
      ?task <http://purl.org/dc/terms/isPartOf> / <http://mu.semte.ch/vocabularies/ext/codelist> ?codelist .
      FILTER NOT EXISTS {
        ?someTask <http://redpencil.data.gift/vocabularies/tasks/operation> <http://lblod.data.gift/id/jobs/concept/TaskOperation/codelist-matching/annotate> .
        ?someTask <http://redpencil.data.gift/vocabularies/tasks/inputContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?resource .
        ?someTask <http://purl.org/dc/terms/isPartOf> / <http://mu.semte.ch/vocabularies/ext/codelist> ?codelist .
      }
      FILTER NOT EXISTS {
        ?original <http://purl.org/linguistics/gold/translation> ?resource .
      }`,
  },
  {
    currentOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/annotation-split-tasks',
    nextOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/translating',
    resourceLimit: 1000,
    resourceFilter: `
      FILTER NOT EXISTS {
        ?original <http://purl.org/linguistics/gold/translation> ?resource .
      }
      FILTER NOT EXISTS {
        ?someTask <http://redpencil.data.gift/vocabularies/tasks/operation> <http://lblod.data.gift/id/jobs/concept/TaskOperation/translating> .
        ?someTask <http://redpencil.data.gift/vocabularies/tasks/inputContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?resource .
      }
`,
  },
  {
    currentOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/split-task-json-to-eli',
    nextOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/translating',
  },
  {
    currentOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/split-task-pdf-to-enriched-translating',
    nextOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/translating',
  },
  {
    currentOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/pdf-to-eli-scraping-split',
    nextOperation:
      'http://lblod.data.gift/id/jobs/concept/TaskOperation/pdf-scraping',
    harvestingCollection: true,
  },
];
