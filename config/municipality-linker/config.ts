export const municipalityLink = `
    ?target a org:Organization .
    {
      ?decision ^<http://data.europa.eu/eli/ontology#is_realized_by> / <http://data.europa.eu/eli/ontology#passed_by> / ^<http://www.w3.org/ns/org#hasSubOrganization> ?target .
    } UNION {
      ?annotation oa:hasTarget / oa:hasSource? ?decision .
      ?annotation oa:hasBody ?body .
      ?body rdf:predicate <http://data.europa.eu/eli/ontology#passed_by> .
      ?body rdf:body ?target .
    } UNION {
      ?task <http://redpencil.data.gift/vocabularies/tasks/inputContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?target .
      ?task <http://redpencil.data.gift/vocabularies/tasks/inputContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?decision .
      ?decision a eli:Expression.
    } UNION {
      ?task1 <http://purl.org/dc/terms/isPartOf> ?job .
      ?task2 <http://purl.org/dc/terms/isPartOf> ?job .
      ?task1 <http://redpencil.data.gift/vocabularies/tasks/inputContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?target .
      ?task2 <http://redpencil.data.gift/vocabularies/tasks/resultsContainer> / <http://redpencil.data.gift/vocabularies/tasks/hasResource> ?decision .
      ?decision a eli:Expression.
      FILTER NOT EXISTS {
        ?original <http://purl.org/linguistics/gold/translation> ?decision .
      }
    }
  `;
