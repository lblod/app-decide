import harvest from "./harvest";
import jobController from "./job-controller";
import pdfToEli from "./pdf-to-eli";
import osloToEli from "./oslo-to-eli";
import search from "./search";

export default [
  ...harvest,
  ...jobController,
  ...pdfToEli,
  ...osloToEli,
  ...search,
];
