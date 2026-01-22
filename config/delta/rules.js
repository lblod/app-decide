import harvest from "./harvest";
import jobController from "./job-controller";
import pdfToEli from "./pdf-to-eli";

export default [...harvest, ...jobController, ...pdfToEli];