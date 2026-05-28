import { initialization, PUBLIC_GRAPH_FILTER } from './initialization';

export type HealingConfig = Awaited<ReturnType<typeof getHealingConfig>>;
export const getHealingConfig = async () => {
  // TODO: support for multiple streams will be added later on.
  const publicStream = 'public';
  const streams = {
    public: { graphFilter: PUBLIC_GRAPH_FILTER, entities: {} },
  };

  const stream = initialization[publicStream];
  const entities = {};
  Object.keys(stream).forEach((resourceType) => {
    const entity = stream[resourceType];
    if (entity.healingPredicates) {
      entities[resourceType] = {
        healingPredicates: entity.healingPredicates,
        instanceFilter: entity.filter,
      };
    }
  });

  streams[publicStream].entities = entities;

  return streams;
};
