import { sparqlEscapeUri } from 'mu';

export const PUBLIC_GRAPH = 'http://mu.semte.ch/graphs/public';

const PUBLIC_GRAPH_FILTER = `
  VALUES ?g {
    ${sparqlEscapeUri(PUBLIC_GRAPH)}
  }`;

export const initialization = {
  public: {
    'http://www.w3.org/ns/dcat#Catalog': {
      graphFilter: PUBLIC_GRAPH_FILTER,
    },
    'http://www.w3.org/ns/dcat#Dataset': {
      graphFilter: PUBLIC_GRAPH_FILTER,
    },
    'http://www.w3.org/ns/dcat#Distribution': {
      graphFilter: PUBLIC_GRAPH_FILTER,
    },
    'http://www.w3.org/ns/dcat#DataService': {
      graphFilter: PUBLIC_GRAPH_FILTER,
    },
    'http://www.w3.org/ns/dcat#CatalogRecord': {
      graphFilter: PUBLIC_GRAPH_FILTER,
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
    },
  },
};
