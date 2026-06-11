import harvest from './harvest';
import resource from './resource.js';
import jobController from './job-controller.js';
import codelist from './codelist.js';
import annotationJobSplitter from './annotation-job-splitter.js';

export default [
  ...resource,
  ...harvest,
  ...jobController,
  ...codelist,
  ...annotationJobSplitter,
];
