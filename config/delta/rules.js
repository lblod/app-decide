import harvest from './harvest';
import jobController from './job-controller';
import pdfToEli from './pdf-to-eli';
import osloToEli from './oslo-to-eli';
import search from './search';
import resource from './resource';
import codelist from './codelist';
import annotationJobSplitter from './annotation-job-splitter';
import ldes from './ldes';
import jsonToEli from './json-to-eli';

export default [
  ...resource,
  ...harvest,
  ...jobController,
  ...pdfToEli,
  ...osloToEli,
  ...jsonToEli,
  ...search,
  ...codelist,
  ...annotationJobSplitter,
  ...ldes,
];
