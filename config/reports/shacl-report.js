import {
  mergeFilesContent,
  parseTurtleString,
  validateDataset,
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

import { sparqlEscapeUri } from "mu";
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
        
        const dataDataset = new Store();

        fillDataDataset(dataDataset, shapesDataset, sparqlShapeDataset);

        console.log(
            `Running SHACL validation on store of size ${dataDataset.size}...`
        );
        const startTime = Date.now();
        const reportDataset = await validateDataset(dataDataset, shapesDataset);
        console.log(`Running SPARQL-based constraints...`);
        await addSparqlValidationsToReport(
            dataDataset,
            reportDataset,
            sparqlValidationObjects
        );
        const endTime = Date.now();
        console.log(
            `SHACL validation took ${(endTime - startTime) / 1000} seconds.`
        );

        await saveDatasetToNamedGraphs(reportDataset, namedGraphs);
        console.log(`SHACL validation report saved in triple store.`);

        if (ONLY_KEEP_LATEST_REPORT) {
            await deletePreviousShaclValidationReports(namedGraphs);
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

// Fill dataDataset, one level deep (?resource ?p ?o), with resources of type target class in the shape files and sparql-based shapes
async function fillDataDataset(dataDataset, shapesDataset, sparqlShapeDataset) {
    const targetClassesShacl = [...shapesDataset.match(
        null,
        namedNode("http://www.w3.org/ns/shacl#targetClass"),
        null
    )].map(q => q.object.value);
    const targetClassesSparql = [...sparqlShapeDataset.match(
        null,
        namedNode("http://www.w3.org/ns/shacl#targetClass"),
        null
    )].map(q => q.object.value);
    const allTargetClasses = [
        ...new Set([
            ...targetClassesShacl,
            ...targetClassesSparql
        ])
    ];
    for (const targetClass of allTargetClasses) {
        const count = await countResources(targetClass, namedGraphs);
        console.log(`Adding ${count} resources for graphs ${safeNamedGraphs} and resource type ${targetClass}...`);
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
            await addResourcesOneLevelDeep(dataDataset, namedGraphs, resources);
        }
    }
}