import harvest from './harvest';
import jobController from './job-controller';
import pdfToEli from './pdf-to-eli';
import osloToEli from './oslo-to-eli';
import search from './search';
import resource from './resource';
import codelist from './codelist';

export default [
  ...resource,
  ...harvest,
  ...jobController,
  ...pdfToEli,
  ...osloToEli,
  ...search,
  ...codelist,
];
