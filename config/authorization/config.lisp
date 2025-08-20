; CONFIGURATION

(in-package :client)
(setf *log-sparql-query-roundtrip* t)
(setf *backend* "http://virtuoso:8890/sparql")

(in-package :server)
(setf *log-incoming-requests-p* t)

; ACCESS RIGHTS

(in-package :acl)

(define-prefixes
  :eli "http://data.europa.eu/eli/ontology#"
)

(define-graph public ("http://mu.semte.ch/graphs/public")
  ("eli:LegalExpression" -> _))

(supply-allowed-group "public")

(grant (read)
  :to-graph public
  :for-allowed-group "public")