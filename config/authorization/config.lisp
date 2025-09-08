; CONFIGURATION

(in-package :client)
(setf *log-sparql-query-roundtrip* t)
(setf *backend* "http://virtuoso:8890/sparql")

(in-package :server)
(setf *log-incoming-requests-p* t)

; ACCESS RIGHTS

(in-package :acl)

(define-prefixes
  :org "http://www.w3.org/ns/org#"
  :foaf "http://xmlns.com/foaf/0.1/"
  :dct "http://purl.org/dc/terms/"
  :eli "http://data.europa.eu/eli/ontology#"
  :eli-dl "http://data.europa.eu/eli/eli-draft-legislation-ontology#"
  :oparl-temp "http://mu.semte.ch/vocabularies/ext/oparl/"
)

(define-graph public ("http://mu.semte.ch/graphs/public")
  ("org:Organization" -> _)
  ("foaf:Person" -> _)
  ("dct:PeriodOfTime" -> _)
  ("org:Membership" -> _)
  ("oparl-temp:Location" -> _)
  ("eli:Work" -> _)
  ("eli:Expression" -> _)
  ("eli:LegalExpression" -> _)
  ("eli:Manifestation" -> _)
  ("eli:ComplexWork" -> _)
  ("eli-dl:Activity" -> _)
  ("eli-dl:LegislativeProcess" -> _)
  ("eli-dl:LegislativeProcessWork" -> _)
  ("eli-dl:DraftLegislationWork" -> _)
  ("eli-dl:ParliamentaryTerm" -> _)
  ("eli-dl:Participation" -> _)
  ("eli-dl:ForeseenActivity" -> _)
  ("eli-dl:Decision" -> _)
  ("eli-dl:Vote" -> _)
  ("eli-dl:ProcessStage" -> _))

(supply-allowed-group "public")

(grant (read)
  :to-graph public
  :for-allowed-group "public")
