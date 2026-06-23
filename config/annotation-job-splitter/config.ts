export default {
  jobConfiguration: {
    'http://lblod.data.gift/id/jobs/concept/JobOperation/codelist-matching/training':
      {
        taskConfiguration: [
          {
            currentOperation:
              'http://lblod.data.gift/id/jobs/concept/TaskOperation/codelist-matching/training-split-tasks',
            nextOperation:
              'http://lblod.data.gift/id/jobs/concept/TaskOperation/codelist-matching/annotate',
          },
        ],
      },
    'http://lblod.data.gift/id/jobs/concept/JobOperation/codelist-matching/evaluation':
      {
        taskConfiguration: [
          {
            currentOperation:
              'http://lblod.data.gift/id/jobs/concept/TaskOperation/codelist-matching/evaluation-split-tasks',
            nextOperation:
              'http://lblod.data.gift/id/jobs/concept/TaskOperation/codelist-matching/annotate',
          },
        ],
      },
    'http://lblod.data.gift/id/jobs/concept/JobOperation/ner-and-nel-annotations':
      {
        taskConfiguration: [
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
                ?someTask <http://redpencil.data.gift/vocabularies/tasks/operation> <http://lblod.data.gift/id/jobs/concept/TaskOperation/eli-translation> .
                ?someTask <http://redpencil.data.gift/vocabularies/tasks/inputContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?resource .
              }
            `,
          },
        ],
      },
  },
};
