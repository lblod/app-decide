import { sparqlEscapeUri } from 'mu';

export const PUBLIC_GRAPH = 'http://mu.semte.ch/graphs/public';

export const PUBLIC_GRAPH_FILTER = `
  VALUES ?g {
    ${sparqlEscapeUri(PUBLIC_GRAPH)}
}`;

// NOTE (28/05/2026): Not all interesting resources have a triple for this
// predicate already.  It is up to us to add it when updating an existing
// resource, otherwise the changes will not be picked up.
const HEALING_PREDICATE = 'http://purl.org/dc/terms/modified';

export const initialization = {
  public: {
    'http://www.w3.org/ns/dcat#Catalog': {
      graphFilter: PUBLIC_GRAPH_FILTER,
      healingPredicates: [HEALING_PREDICATE],
    },
    'http://www.w3.org/ns/dcat#Dataset': {
      graphFilter: PUBLIC_GRAPH_FILTER,
      healingPredicates: [HEALING_PREDICATE],
    },
    'http://www.w3.org/ns/dcat#Distribution': {
      graphFilter: PUBLIC_GRAPH_FILTER,
      healingPredicates: [HEALING_PREDICATE],
    },
    'http://www.w3.org/ns/dcat#DataService': {
      graphFilter: PUBLIC_GRAPH_FILTER,
      healingPredicates: [HEALING_PREDICATE],
    },
    'http://www.w3.org/ns/dcat#CatalogRecord': {
      graphFilter: PUBLIC_GRAPH_FILTER,
      healingPredicates: [HEALING_PREDICATE],
    },
    'http://xmlns.com/foaf/0.1/Agent': {
      graphFilter: PUBLIC_GRAPH_FILTER,
      filter: `
        FILTER EXISTS {
          ?catalogOrDataset ?publisherOrContactPoint ?s ;
                            a ?type .
          VALUES ?publisherOrContactPoint {
            <http://purl.org/dc/terms/publisher>
            <http://www.w3.org/ns/dcat#contactPoint>
          }
          VALUES ?type {
            <http://www.w3.org/ns/dcat#Catalog>
            <http://www.w3.org/ns/dcat#Dataset>
          }
        }`,
      healingPredicates: [HEALING_PREDICATE],
    },
    'http://www.w3.org/2004/02/skos/core#ConceptScheme': {
      graphFilter: PUBLIC_GRAPH_FILTER,
      filter: `
        GRAPH ?g {
          FILTER EXISTS {
            ?catalog <http://www.w3.org/ns/dcat#themeTaxonomy> ?s ;
                     a ?type .
            VALUES ?type {
              <http://www.w3.org/ns/dcat#Catalog>
            }
          }
        }`,
      healingPredicates: [HEALING_PREDICATE],
    },
    'http://www.w3.org/2004/02/skos/core#Concept': {
      graphFilter: PUBLIC_GRAPH_FILTER,
      filter: `
        GRAPH ?g {
          FILTER EXISTS {
            ?dataset <http://www.w3.org/ns/dcat#theme> ?s ;
                     a ?type .
            VALUES ?type {
              <http://www.w3.org/ns/dcat#Dataset>
            }
          }
        }`,
      healingPredicates: [HEALING_PREDICATE],
    },
    'http://purl.org/dc/terms/MediaTypeOrExtent': {
      graphFilter: PUBLIC_GRAPH_FILTER,
      filter: `
        GRAPH ?g {
          FILTER EXISTS {
            ?distribution <http://purl.org/dc/terms/format> ?s ;
                          a ?type .
            VALUES ?type {
              <http://www.w3.org/ns/dcat#Distribution>
            }
          }
        }`,
      healingPredicates: [HEALING_PREDICATE],
    },
    'http://mu.semte.ch/vocabulary/cms/Page': {
      graphFilter: PUBLIC_GRAPH_FILTER,
      filter: `
        GRAPH ?g {
          FILTER EXISTS {
            ?format <http://mu.semte.ch/vocabulary/cms/page> ?s ;
                    a ?formatType .
            VALUES ?formatType {
              <http://purl.org/dc/terms/MediaTypeOrExtent>
            }
            ?distribution <http://purl.org/dc/terms/format> ?format ;
                          a ?distributionType .
            VALUES ?distributionType {
              <http://www.w3.org/ns/dcat#Distribution>
            }
          }
        }`,
      healingPredicates: [HEALING_PREDICATE],
    },
  },
};

function getElement(stream, type) {
  return initialization[stream]?.[type];
}

export function getGraphFilter(stream, type) {
  return getElement(stream, type)?.graphFilter;
}

export function getFilter(stream, type) {
  return getElement(stream, type)?.filter;
}
