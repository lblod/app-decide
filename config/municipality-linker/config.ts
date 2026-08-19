export const municipalityLink = `
    ?target a org:Organization .
    {
      ?decision ^<http://data.europa.eu/eli/ontology#is_realized_by> / <http://data.europa.eu/eli/ontology#passed_by> / ^<http://www.w3.org/ns/org#hasSubOrganization> ?target .
    } UNION {
      ?annotation oa:hasTarget / oa:hasSource? ?decision .
      ?annotation oa:hasBody ?body .
      ?body rdf:predicate <http://data.europa.eu/eli/ontology#passed_by> .
      ?body rdf:object ?target .
    } UNION {
      ?task <http://redpencil.data.gift/vocabularies/tasks/inputContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?target .
      ?task <http://redpencil.data.gift/vocabularies/tasks/inputContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?decision .
      ?decision a eli:Expression.
    } UNION {
      ?task1 <http://redpencil.data.gift/vocabularies/tasks/index> "0" .
      ?task1 <http://purl.org/dc/terms/isPartOf> ?job .
      ?task2 <http://purl.org/dc/terms/isPartOf> ?job .
      ?task1 <http://redpencil.data.gift/vocabularies/tasks/inputContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?target .
      ?task2 <http://redpencil.data.gift/vocabularies/tasks/resultsContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?decision .
      ?decision a eli:Expression.
      FILTER NOT EXISTS {
        ?original <http://purl.org/linguistics/gold/translation> ?decision .
      }
    } UNION {
      ?task <http://purl.org/dc/terms/isPartOf> ?job .
      ?task <http://redpencil.data.gift/vocabularies/tasks/inputContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?target .
      ?job <http://mu.semte.ch/vocabularies/ext/shapeForTargets> / <http://www.w3.org/ns/shacl#targetNode> ?decision .
      ?decision a eli:Expression.
      FILTER NOT EXISTS {
        ?original <http://purl.org/linguistics/gold/translation> ?decision .
      }
    } UNION {
      BIND(<https://ris.freiburg.de/oparl/body/FR> AS ?target)
      ?task <http://redpencil.data.gift/vocabularies/tasks/resultsContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasHarvestingCollection> / <http://purl.org/dc/terms/hasPart> / <http://www.semanticdesktop.org/ontologies/2007/01/19/nie#url> ?work .
      ?work eli:is_realized_by ?decision .
      FILTER NOT EXISTS {
        ?original <http://purl.org/linguistics/gold/translation> ?decision .
      }

      ?task <http://purl.org/dc/terms/isPartOf> ?job.
      ?job <http://redpencil.data.gift/vocabularies/tasks/operation> <http://lblod.data.gift/id/jobs/concept/JobOperation/harvesting/oparl> .
      FILTER EXISTS {
        ?inputTask <http://purl.org/dc/terms/isPartOf> ?job.
        ?inputTask <http://redpencil.data.gift/vocabularies/tasks/inputContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasHarvestingCollection> / <http://purl.org/dc/terms/hasPart> / <http://www.semanticdesktop.org/ontologies/2007/01/19/nie#url> <https://ris.freiburg.de/oparl> .
      }
    }
  `;
