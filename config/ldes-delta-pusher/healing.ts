import { streams, PUBLIC_GRAPH_FILTER } from './config';

export type HealingConfig = Awaited<ReturnType<typeof getHealingConfig>>;
export const getHealingConfig = async () => {
  // NOTE (03/06/2026): Initially we planned to have multiple streams in our
  // app.  One containing all DCAT data, which is the configured `public`
  // stream.  As well as partner-specific streams, each containing only the DCAT
  // data for that partner.  Therefore, when setting up the `public` stream, it
  // was implemented such to be (at least in theory) easily extensible to
  // multiple feeds.
  // Since we will not be supporting multiple feeds this could be simplified.
  // But considering the limited extra complexity, we decided to leave it as is.
  const publicStream = 'public';
  const resultStreams = {
    public: { graphFilter: PUBLIC_GRAPH_FILTER, entities: {} },
  };

  const stream = streams[publicStream];
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

  resultStreams[publicStream].entities = entities;

  return resultStreams;
};
