; CONFIGURATION

(in-package :client)
(setf *log-sparql-query-roundtrip* t)
(setf *backend* "http://virtuoso:8890/sparql")

(in-package :server)
(setf *log-incoming-requests-p* t)

; ACCESS RIGHTS

(in-package :acl)

(define-prefixes
  :cms "http://mu.semte.ch/vocabulary/cms/"
  :dcat "http://www.w3.org/ns/dcat#"
  :dct "http://purl.org/dc/terms/"
  :eli "http://data.europa.eu/eli/ontology#"
  :eli-dl "http://data.europa.eu/eli/eli-draft-legislation-ontology#"
  :foaf "http://xmlns.com/foaf/0.1/"
  :oparl-temp "http://mu.semte.ch/vocabularies/ext/oparl/"
  :org "http://www.w3.org/ns/org#"
  :skos "http://www.w3.org/2004/02/skos/core#"
)

(define-graph public ("http://mu.semte.ch/graphs/public")
  ("cms:Page" -> _)
  ("dcat:Catalog" -> _)
  ("dcat:Dataset" -> _)
  ("dcat:Distribution" -> _)
  ("dct:MediaTypeOrExtent" -> _)
  ("dct:PeriodOfTime" -> _)
  ("eli-dl:Activity" -> _)
  ("eli-dl:Decision" -> _)
  ("eli-dl:DraftLegislationWork" -> _)
  ("eli-dl:ForeseenActivity" -> _)
  ("eli-dl:LegislativeProcess" -> _)
  ("eli-dl:LegislativeProcessWork" -> _)
  ("eli-dl:ParliamentaryTerm" -> _)
  ("eli-dl:Participation" -> _)
  ("eli-dl:ProcessStage" -> _)
  ("eli-dl:Vote" -> _)
  ("eli:ComplexWork" -> _)
  ("eli:Expression" -> _)
  ("eli:LegalExpression" -> _)
  ("eli:Manifestation" -> _)
  ("eli:Work" -> _)
  ("foaf:Agent" -> _)
  ("foaf:Person" -> _)
  ("oparl-temp:Location" -> _)
  ("org:Membership" -> _)
  ("org:Organization" -> _)
  ("skos:Concept" -> _)
  ("skos:ConceptScheme" -> _)
)

(supply-allowed-group "public")

(grant (read)
  :to-graph public
  :for-allowed-group "public")
