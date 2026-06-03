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

const RESOURCE_TYPES = {
  catalog: 'http://www.w3.org/ns/dcat#Catalog',
  dataset: 'http://www.w3.org/ns/dcat#Dataset',
  distribution: 'http://www.w3.org/ns/dcat#Distribution',
  dataService: 'http://www.w3.org/ns/dcat#DataService',
  catalogRecord: 'http://www.w3.org/ns/dcat#CatalogRecord',
  agent: 'http://xmlns.com/foaf/0.1/Agent',
  conceptScheme: 'http://www.w3.org/2004/02/skos/core#ConceptScheme',
  concept: 'http://www.w3.org/2004/02/skos/core#Concept',
  mediaTypeOrExtend: 'http://purl.org/dc/terms/MediaTypeOrExtent',
  page: 'http://mu.semte.ch/vocabulary/cms/Page',
};

const PUBLIC_FILTERS = {
  agent: `
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
  conceptScheme: `
    GRAPH ?g {
      FILTER EXISTS {
        ?catalog <http://www.w3.org/ns/dcat#themeTaxonomy> ?s ;
                 a ?type .
        VALUES ?type {
          <http://www.w3.org/ns/dcat#Catalog>
        }
      }
    }`,
  concept: `
    GRAPH ?g {
      FILTER EXISTS {
        ?dataset <http://www.w3.org/ns/dcat#theme> ?s ;
                 a ?type .
        VALUES ?type {
          <http://www.w3.org/ns/dcat#Dataset>
        }
      }
    }`,
  mediaTypeOrExtent: `
    GRAPH ?g {
      FILTER EXISTS {
        ?distribution <http://purl.org/dc/terms/format> ?s ;
                      a ?type .
        VALUES ?type {
          <http://www.w3.org/ns/dcat#Distribution>
        }
      }
    }`,
  page: `
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
};

type FilterConfig = {
  [resourceType: string]: string;
};
type ResourceConfig = {
  graphFilter: string;
  healingPredicates: string[];
  filter?: string;
};
type StreamConfig = {
  [resourceType: string]: ResourceConfig;
};

function constructStream(filters: FilterConfig): StreamConfig {
  const stream = {};
  for (const resource of Object.keys(RESOURCE_TYPES)) {
    const r: ResourceConfig = {
      graphFilter: PUBLIC_GRAPH_FILTER,
      healingPredicates: [HEALING_PREDICATE],
    };
    if (filters[resource]) {
      r.filter = filters[resource];
    }
    stream[RESOURCE_TYPES[resource]] = r;
  }
  return stream;
}

export const streams = {
  public: constructStream(PUBLIC_FILTERS),
  // TODO: This is for testing.  This should use other filters that keep out
  // non-Freiburg data.
  freiburg: constructStream(PUBLIC_FILTERS),
};

function getElement(stream, type) {
  return stream[stream]?.[type];
}

export function getGraphFilter(stream, type) {
  return getElement(stream, type)?.graphFilter;
}

export function getFilter(stream, type) {
  return getElement(stream, type)?.filter;
}
