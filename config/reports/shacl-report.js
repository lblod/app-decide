import {
  mergeFilesContent,
  parseTurtleString,
  validateDataset,
  enrichValidationReport,
  saveDatasetToNamedGraphs,
  deletePreviousShaclValidationReports,
  getSparqlValidationObjects,
  addSparqlValidationsToReport,
  addResourcesOneLevelDeep,
  countResources,
} from "../helpers.js";

import env from "env-var";
const ONLY_KEEP_LATEST_REPORT =
  process.env.ONLY_KEEP_LATEST_REPORT != undefined
    ? env.get("ONLY_KEEP_LATEST_REPORT").asBool()
    : false;

export const BATCH_SIZE = env
  .get('BATCH_SIZE')
  .default('100')
  .asIntPositive();

import { app, query, sparqlEscapeString, sparqlEscapeUri } from "mu";
import { querySudo } from '@lblod/mu-auth-sudo';

import { Store, DataFactory } from "n3";
const { namedNode } = DataFactory;

const CRON_PATTERN = "0 3 * * *";
const REPORT_NAME = "ELI validation of Decide";

const namedGraphs = [
    'http://mu.semte.ch/graphs/public/freiburg',
    'http://mu.semte.ch/graphs/public/gent',
    'http://mu.semte.ch/graphs/public/pdf',
]
const safeNamedGraphs = namedGraphs
  .map((uri) => sparqlEscapeUri(uri))
  .join('\n');

const cronFunction = async (namedGraph = null) => {
    console.log("report starts");
    try {
        // Read all SHACL files in the shacl folder
        const shape = await mergeFilesContent("./config/shacl");
        const sparqlShapes = await mergeFilesContent("./config/sparql");
        const shapesDataset = await parseTurtleString(shape);
        const sparqlShapeDataset = await parseTurtleString(sparqlShapes);
        const sparqlValidationObjects = await getSparqlValidationObjects(
            sparqlShapeDataset
        );

        const targetClasses = [...shapesDataset.match(
          null,
          namedNode("http://www.w3.org/ns/shacl#targetClass"),
          null
        )].map(q => q.object.value);
        
        for (const targetClass of targetClasses) {
            const dataDataset = new Store();
            const count = await countResources(targetClass, namedGraphs);

            for (let offset = 0; offset < count; offset += BATCH_SIZE) {
                const resources = [];
                const resourcesResult = await querySudo(`
                SELECT DISTINCT ?resource
                WHERE {
                        VALUES ?graph {
                            ${safeNamedGraphs}
                        }

                        GRAPH ?graph {
                            ?resource a ${sparqlEscapeUri(targetClass)} .
                        }
                    }
                LIMIT ${BATCH_SIZE}
                OFFSET ${offset}
                `);
                resourcesResult.results.bindings.forEach((binding) => {
                    resources.push(binding.resource.value);
                });
                console.log(`Adding ${resources.length} resources for graphs ${safeNamedGraphs} and resource type ${targetClass}...`);
                await addResourcesOneLevelDeep(dataDataset, namedGraphs, resources);
            }

            console.log(
                `Running SHACL validation for target class ${targetClass} on store of size ${dataDataset.size}...`
            );
            const startTime = Date.now();
            const report = await validateDataset(dataDataset, shapesDataset);
            const endTime = Date.now();
            console.log(
                `SHACL validation took ${(endTime - startTime) / 1000} seconds.`
            );

            // Enrich validation report by removing blank nodes, adding timestamp etc.
            const { reportUri, reportDataset } = enrichValidationReport(
                report.dataset,
                shapesDataset,
                dataDataset
            );
                        console.log(reportDataset.toString())

            await addSparqlValidationsToReport(
                dataDataset,
                reportDataset,
                sparqlValidationObjects
            );

            await saveDatasetToNamedGraphs(reportDataset, namedGraphs);
            console.log(`SHACL validation report (${reportUri}) saved in triple store.`);

            if (ONLY_KEEP_LATEST_REPORT) {
                await deletePreviousShaclValidationReports(namedGraphs);
            }

            console.log(`SHACL validation for target class ${targetClass} done on named graphs ${safeNamedGraphs}`);
        }
        console.log(`Done validating.`);
    } catch (error) {
      console.error("Error:", error);
    }
  };

if (process.env.RUN_REPORT_NOW) {
  console.log("Running report in 2 seconds");
  setTimeout(() => cronFunction(), 2000);
}

export default {
  cronPattern: CRON_PATTERN,
  name: REPORT_NAME,
  execute: cronFunction,
};