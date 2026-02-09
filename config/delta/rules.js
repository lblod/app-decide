import harvest from './harvest';
import jobController from './job-controller';
import pdfToEli from './pdf-to-eli';
import search from './search';

export default [...harvest, ...jobController, ...pdfToEli, ...search];
