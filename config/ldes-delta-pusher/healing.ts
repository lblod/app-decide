import { initialization } from './initialization';

export type HealingConfig = Awaited<ReturnType<typeof getHealingConfig>>;
// NOTE (20/05/2026): Modified from configuration in OPH
// <https://github.com/lblod/app-openproceshuis/blob/development/config/ldes-delta-pusher/healing.ts>
export const getHealingConfig = async () => {
  const entities: any = {};
  Object.keys(initialization).map((typeUri) => {
    if (initialization[typeUri].healingPredicates) {
      entities[typeUri] = {
        healingPredicates: initialization[typeUri].healingPredicates,
        instanceFilter: initialization[typeUri].filter,
      };
    }
  });

  return {
    public: {
      entities,
    },
  };
};
