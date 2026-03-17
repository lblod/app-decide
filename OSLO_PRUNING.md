The OSLO configuration depends on consuming all data from a full LBLOD harvester. This results in a lot of extra data that is not necessary, only the Ghent decisions are used in Decide.

The following queries allow you to remove most of the unnecessary data and trim the db to a manageable size

The queries will remove non-ghent decisions (easily identifiable because they are not in the ghent target graph after the oslo pipeline has run) and then proceed to progressively remove unlinked items.

## remove non-ghent decisions

    PREFIX besluit: <http://data.vlaanderen.be/ns/besluit#>
    DELETE {
      GRAPH <http://mu.semte.ch/graphs/oslo-decisions/landing> {
        ?s ?p ?o.
      }
    }WHERE {
      GRAPH <http://mu.semte.ch/graphs/oslo-decisions/landing> {
        ?s a besluit:Besluit.
        ?s ?p ?o.
      }
      FILTER NOT EXISTS {
        GRAPH <http://mu.semte.ch/graphs/public/gent> {
          ?s a <http://data.europa.eu/eli/ontology#Expression>
        }
      }
    }

## remove behandelingen that are not useful

    DELETE {
      GRAPH ?g {
        ?s ?p ?o.
      }
    }
    WHERE {
      GRAPH ?g {
        ?s a <http://data.vlaanderen.be/ns/besluit#BehandelingVanAgendapunt>.
        ?s ?p ?o.
        FILTER NOT EXISTS {
          ?besluit <http://www.w3.org/ns/prov#wasGeneratedBy> ?s.
        }
      }
    }

## remove agendapunten without behandeling

    DELETE {
      GRAPH ?g {
        ?s ?p ?o.
      }
    }WHERE {
      GRAPH ?g {
        ?s a <http://data.vlaanderen.be/ns/besluit#Agendapunt>.
        ?s ?p ?o.

        FILTER NOT EXISTS {
          ?behandeling <http://data.vlaanderen.be/ns/besluit#behandelt> ?s.
          ?behandeling a <http://data.vlaanderen.be/ns/besluit#BehandelingVanAgendapunt>.
        }
      }
    }

## remove artikels

    DELETE {
      GRAPH ?g {
        ?s ?p ?o.
      }
    }WHERE {
      GRAPH ?g {
        ?s a <http://data.vlaanderen.be/ns/besluit#Artikel>.
        ?s ?p ?o.
        FILTER NOT EXISTS {
          ?besluit <http://data.europa.eu/eli/ontology#has_part> ?s.
        }
      }
    }

## remove stemming

    DELETE {
      GRAPH ?g {
        ?s ?p ?o.
      }
    }WHERE {
      GRAPH ?g {
        ?s a <http://data.vlaanderen.be/ns/besluit#Stemming> .
        ?s ?p ?o.
        FILTER NOT EXISTS {
          ?agendapunt <http://data.vlaanderen.be/ns/besluit#heeftStemming> ?s.
          ?agendapunt a ?thing.
        }
      }
    }

## remove zittingen

    DELETE {
      GRAPH ?g {
        ?s ?p ?o.
      }
    }WHERE {
      GRAPH ?g {
        ?s a <http://data.vlaanderen.be/ns/besluit#Zitting> .
        ?s ?p ?o.
        FILTER NOT EXISTS {
          ?s <http://mu.semte.ch/vocabularies/ext/behandelt> ?o.
          ?o a <http://data.vlaanderen.be/ns/besluit#BehandelingVanAgendapunt> .
        }
      }
    }

## remove documents

      DELETE {
        GRAPH <http://mu.semte.ch/graphs/oslo-decisions/landing> {
          ?s ?p ?o.
        }
      }WHERE {
        GRAPH <http://mu.semte.ch/graphs/oslo-decisions/landing> {
          ?s a <http://xmlns.com/foaf/0.1/Document>.
          ?s ?p ?o.
          FILTER NOT EXISTS {
          VALUES ?thing {
    <http://data.vlaanderen.be/ns/besluit#BehandelingVanAgendapunt>
    <http://data.vlaanderen.be/ns/besluit#Stemming>
    <http://data.vlaanderen.be/ns/besluit#Besluit>
    <http://data.vlaanderen.be/ns/besluit#Zitting>

            }
            ?oo ?pp ?s .
            ?oo a ?thing.
          }
        }
      }
