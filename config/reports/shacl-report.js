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

const RUN_REPORT_NOW = 
  process.env.RUN_REPORT_NOW != undefined
    ? env.get("RUN_REPORT_NOW").asBool()
    : false;

export const BATCH_SIZE = env
  .get('BATCH_SIZE')
  .default('100')
  .asIntPositive();

export const RUN_SPARQL_VALIDATIONS = env
  .get('RUN_SPARQL_VALIDATIONS')
  .default('false')
  .asBool();

export const SAMPLING_ENABLED = env
  .get('SAMPLING_ENABLED')
  .default('true')
  .asBool();

export const SAMPLING_SIZE = env
  .get('SAMPLING_SIZE')
  .default('100')
  .asIntPositive();
  
import { sparqlEscapeUri, uuid } from "mu";
import { querySudo } from '@lblod/mu-auth-sudo';

import { Store, DataFactory } from "n3";
const { quad, namedNode, literal } = DataFactory;

const CRON_PATTERN = "0 3 * * *";
const REPORT_NAME = "ELI validation of Decide";
const MAX_STRING_LENGTH = '100'; // string values will be shortened when inserting in temporary validation graph for sparql-based constraints

const namedGraphs = [
    'http://mu.semte.ch/graphs/public/freiburg',
    'http://mu.semte.ch/graphs/public/gent',
    'http://mu.semte.ch/graphs/public/pdf',
];

const safeNamedGraphs = namedGraphs
  .map((uri) => sparqlEscapeUri(uri))
  .join('\n');

const cronFunction = async (namedGraph = null) => {
    await waitForDatabase();
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
        
        const allTargetClasses = retrieveTargetClasses([shapesDataset, sparqlShapeDataset]);
        // Validation happens in batches (fill, validate, save), so we don't need to insert all data in memory first
        // Key is to pass a reportURI to the validation function, so all results are linked to the same report
        const reportUUID = uuid();
        const reportURI = `http://data.lblod.info/id/reports/${reportUUID}`;
        const created = new Date().toISOString();
        for (const targetClass of allTargetClasses) {
            const totalCount = await countResources(targetClass, namedGraphs);
            const count = SAMPLING_ENABLED ? Math.min(totalCount, SAMPLING_SIZE) : totalCount;
            console.log(`Adding ${count} resources for graphs ${safeNamedGraphs} and resource type ${targetClass}${SAMPLING_ENABLED ? ` (sampling enabled, total: ${totalCount})` : ''}...`);
            for (let offset = 0; offset < count; offset += BATCH_SIZE) {
                const dataDataset = new Store();
                await fillDataDataset(targetClass, offset, count, dataDataset);
                const batchReportDataset = await validateShapesAndSparql(dataDataset, shapesDataset, sparqlValidationObjects, reportURI, reportUUID);
                addTimestamps(batchReportDataset, reportURI, created);
                await saveDatasetToNamedGraphs(batchReportDataset, namedGraphs);
            }
            console.log(`SHACL validation done for target class ${targetClass}.`);
        }
        if (ONLY_KEEP_LATEST_REPORT) {
            await deletePreviousShaclValidationReports(namedGraphs);
        }
        console.log(`Done validating.`);
    } catch (error) {
      console.error("Error:", error);
    }
  };
if (RUN_REPORT_NOW) {
  console.log("Running report in 2 seconds");
  setTimeout(() => cronFunction(), 2000);
}

export default {
  cronPattern: CRON_PATTERN,
  name: REPORT_NAME,
  execute: cronFunction,
};

// Fill dataDataset, one level deep (?resource ?p ?o), with resources of type target class
async function fillDataDataset(targetClass, offset, count, dataDataset) {
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
    LIMIT ${Math.min(BATCH_SIZE, count - offset)}
    OFFSET ${offset}
    `);
    resourcesResult.results.bindings.forEach((binding) => {
        resources.push(binding.resource.value);
    });
    await addResourcesOneLevelDeep(dataDataset, namedGraphs, resources);

    // Shorten strings to avoid insert problems
    dataDataset.forEach((quad) => {
        if (quad.object.termType === 'Literal' && 
            typeof quad.object.value === 'string' &&
            quad.object.value.length > MAX_STRING_LENGTH
        ) {
            const shortenedValue = quad.object.value.slice(0, MAX_STRING_LENGTH);
            let shorterObject;
            if (quad.object.language) {
                // language-tagged literal
                shorterObject = literal(shortenedValue, quad.object.language);
            } else if (quad.object.datatype) {
                // typed literal
                shorterObject = literal(shortenedValue, quad.object.datatype);
            } else {
                // plain literal fallback
                shorterObject = literal(shortenedValue);
            }

            // Replace quad
            dataDataset.removeQuad(quad);
            dataDataset.addQuad(
                quad.subject,
                quad.predicate,
                shorterObject,
                quad.graph // preserve graph if present
            );
        }
    })
}

async function validateShapesAndSparql(dataDataset, shapesDataset, sparqlValidationObjects, reportURI, reportUUID) {
    console.log(
            `Running SHACL validation on store of size ${dataDataset.size}...`
    );
    const startTime = Date.now();
    console.log(`Running non-SPARQL-based constraints...`);
    const reportDataset = await validateDataset(dataDataset, shapesDataset, reportURI, reportUUID);
    if (RUN_SPARQL_VALIDATIONS) {
        console.log(`Running SPARQL-based constraints...`);
        await addSparqlValidationsToReport(
            dataDataset,
            reportDataset,
            sparqlValidationObjects
        );
    }
    const endTime = Date.now();
    console.log(
        `SHACL validation took ${(endTime - startTime) / 1000} seconds.`
    );
    return reportDataset;
}

function retrieveTargetClasses(datasets) {
    const allTargetClasses = new Set();
    datasets.forEach(dataset => {
        [...dataset.match(
            null,
            namedNode("http://www.w3.org/ns/shacl#targetClass"),
            null
        )]
        .map(q => allTargetClasses.add(q.object.value));
    });
    return allTargetClasses;
}

function addTimestamps(reportDataset, reportURI, createdTime) {
    // Add creation time stamp
    // This is used to delete previous reports when ONLY_KEEP_LATEST_REPORT is true
    reportDataset.add(
        quad(
            namedNode(reportURI),
            namedNode('http://purl.org/dc/terms/created'),
            literal(
                createdTime,
                namedNode('http://www.w3.org/2001/XMLSchema#dateTime'),
            ),
        ),
    );
    // Add modified time stamp
    reportDataset.add(
        quad(
            namedNode(reportURI),
            namedNode('http://purl.org/dc/terms/modified'),
            literal(
                createdTime,
                namedNode('http://www.w3.org/2001/XMLSchema#dateTime'),
            ),
        ),
    );
}

async function waitForDatabase() {
  const maxRetries = 30;
  const delayMs = 2000;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await querySudo('ASK { ?s ?p ?o }');
      console.log('Database connection established');
      return;
    } catch {
      console.log(`Waiting for database... (attempt ${attempt}/${maxRetries})`);
      if (attempt === maxRetries) {
        throw new Error(
          `Failed to connect to database after ${maxRetries} attempts`,
        );
      }
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }
}