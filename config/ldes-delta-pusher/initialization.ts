import { streams } from './config';

// NOTE (01/06/2026): The `healingPredicates` property for each resource type is
// actually irrelevant here.  But filtering it out just adds complexity and it
// does not break anything.  So we kept it simple here.
export const initialization = streams;
