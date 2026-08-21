import { app, errorHandler } from "mu";
import { querySudo as query } from '@lblod/mu-auth-sudo';

function escapeCsvField(value) {
  if (value === undefined || value === null) return "";
  const str = String(value);
  if (/[",\n]/.test(str)) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

function sparqlJsonToPivotedCsv(sparqlResult, rowVar, colVar, valueVar) {
  const bindings = sparqlResult.results.bindings;

  // Collect ordered unique row and column values, preserving first-seen order
  const rowValues = [];
  const colValues = [];
  const seenRows = new Set();
  const seenCols = new Set();

  // lookup[row][col] = value
  const lookup = {};

  for (const binding of bindings) {
    const rowKey = binding[rowVar] ? binding[rowVar].value : "";
    const colKey = binding[colVar] ? binding[colVar].value : "";
    const val = binding[valueVar] ? binding[valueVar].value : "";

    if (!seenRows.has(rowKey)) {
      seenRows.add(rowKey);
      rowValues.push(rowKey);
    }
    if (!seenCols.has(colKey)) {
      seenCols.add(colKey);
      colValues.push(colKey);
    }

    if (!lookup[rowKey]) lookup[rowKey] = {};
    lookup[rowKey][colKey] = val;
  }

  const header = [rowVar, ...colValues].map(escapeCsvField).join(",");
  const lines = rowValues.map((row) => {
    const cells = colValues.map((col) =>
      escapeCsvField(lookup[row][col] !== undefined ? lookup[row][col] : "")
    );
    return [escapeCsvField(row), ...cells].join(",");
  });

  return [header, ...lines].join("\n");
}

app.get("/", async function (req, res) {
  try {
    const format = req.query.format;
    const result = await query(`
        PREFIX task: <http://redpencil.data.gift/vocabularies/tasks/>
        PREFIX eli:  <http://data.europa.eu/eli/ontology#>
        PREFIX oa:   <http://www.w3.org/ns/oa#>
        PREFIX dct:  <http://purl.org/dc/terms/>
        PREFIX adms: <http://www.w3.org/ns/adms#>
        PREFIX ext:  <http://mu.semte.ch/vocabularies/ext/>
        PREFIX sh:   <http://www.w3.org/ns/shacl#>
        PREFIX org: <http://www.w3.org/ns/org#>
        PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX gold: <http://purl.org/linguistics/gold/>

        SELECT ?metric (str(?municipalityLabel) as ?city) ?decisions WHERE {
        VALUES ?municipality { <https://ris.freiburg.de/oparl/body/FR> <https://decide.smartcitybamberg.de/organizations#c8e6b8ef-0a33-425a-b9d5-96354823f6e7> <http://data.lblod.info/id/bestuurseenheden/353234a365664e581db5c2f7cc07add2534b47b8e1ab87c821fc6e6365e6bef5> }
        ?municipality skos:prefLabel ?municipalityLabel .

        {
        SELECT ?metric ?municipality (COUNT(DISTINCT ?res) AS ?decisions) WHERE {
        ?res a eli:Expression ;
            ext:owningBody ?municipality .
        FILTER NOT EXISTS {
            ?o gold:translation ?res.
        }
        BIND("1. ELI" AS ?metric)
        }
        group by ?metric ?municipality
        }
        UNION
        {
        SELECT ?metric ?municipality (COUNT(DISTINCT ?res) AS ?decisions) WHERE {
        
        {
        VALUES ?codelist { <http://lblod.data.gift/id/conceptscheme/sdg-simple> <http://lblod.data.gift/id/conceptscheme/restricted-mobility-zone-simple>}
        ?task task:operation <http://lblod.data.gift/id/jobs/concept/TaskOperation/codelist-matching/annotate> .
        ?job ext:codelist ?codelist .
        BIND(IF(?codelist = <http://lblod.data.gift/id/conceptscheme/sdg-simple>, "2. codelist SDG", IF(?codelist = <http://lblod.data.gift/id/conceptscheme/restricted-mobility-zone-simple>, "3. codelist RMZ", "")) AS ?metric)
        } UNION {
        ?task task:operation <http://lblod.data.gift/id/jobs/concept/TaskOperation/entity-extracting> .
            BIND("4. NER" AS ?metric)
        } UNION {
        ?task task:operation <http://lblod.data.gift/id/jobs/concept/TaskOperation/named-entity-linking> .
            BIND("5. NEL" AS ?metric)
        }

        ?task dct:isPartOf ?job .
                    ?job adms:status <http://redpencil.data.gift/id/concept/JobStatus/success> .
        {
            { ?task task:inputContainer ?c } UNION { ?task task:resultsContainer ?c } 
            
            # the expression itself
            { ?c task:hasResource ?res }
            # NER: container holds the translated expression
            UNION { ?c task:hasResource ?x . ?res gold:translation ?x }
            # NEL: container holds annotations on the expression
            UNION { ?c task:hasResource ?a . ?a oa:hasTarget/oa:hasSource ?res }
            # NEL: container holds annotations on the translated expression
            UNION { ?c task:hasResource ?a . ?a oa:hasTarget/oa:hasSource ?y . ?res gold:translation ?y }
        }
        UNION { ?job ext:shapeForTargets/sh:targetNode ?res }

        ?res a eli:Expression ;
            ext:owningBody ?municipality .
        FILTER NOT EXISTS {
            ?o <http://purl.org/linguistics/gold/translation> ?res.
        }
        }
        group by ?metric ?municipality
        }
        }
        order by ?metric ?city
    `);

    if (format === "json") {
      res.send(result);
    } else {
      const csv = sparqlJsonToPivotedCsv(result, "metric", "city", "decisions");
      res.set("Content-Type", "text/csv");
      res.set("Content-Disposition", "attachment; filename=overview.csv");
      res.send(csv);
    }
  } catch {
    res.status(500).send("error occurred");
  }
});

app.use(errorHandler);