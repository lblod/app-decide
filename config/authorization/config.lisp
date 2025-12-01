;;;;;;;;;;;;;;;;;;;
;;; delta messenger
(in-package :delta-messenger)

(setf *delta-handlers* nil)
(add-delta-logger)
(add-delta-messenger "http://deltanotifier/")


; CONFIGURATION

(in-package :client)
(setf *log-sparql-query-roundtrip* t)
(setf *backend* "http://virtuoso:8890/sparql")

(in-package :server)
(setf *log-incoming-requests-p* t)

; ACCESS RIGHTS

(in-package :acl)

(define-prefixes
  :besluit "http://data.vlaanderen.be/ns/besluit#"
  :cms "http://mu.semte.ch/vocabulary/cms/"
  :dcat "http://www.w3.org/ns/dcat#"
  :dct "http://purl.org/dc/terms/"
  :eli "http://data.europa.eu/eli/ontology#"
  :eli-dl "http://data.europa.eu/eli/eli-draft-legislation-ontology#"
  :foaf "http://xmlns.com/foaf/0.1/"
  :oparl-temp "http://mu.semte.ch/vocabularies/ext/oparl/"
  :org "http://www.w3.org/ns/org#"
  :skos "http://www.w3.org/2004/02/skos/core#"
  :cogs "http://vocab.deri.ie/cogs#"
  :core "http://open-services.net/ns/core#"
  :generiek "https://data.vlaanderen.be/ns/generiek#"
  :harvesting "http://lblod.data.gift/vocabularies/harvesting/"
  :mandaat "http://data.vlaanderen.be/ns/mandaat#"
  :ndo "http://oscaf.sourceforge.net/ndo.html#"
  :nfo "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#"
  :person "http://www.w3.org/ns/person#"
  :ext "http://mu.semte.ch/vocabularies/ext/"
  :schema "http://schema.org/"
  :security "http://lblod.data.gift/vocabularies/security/"
  :tasks "http://redpencil.data.gift/vocabularies/tasks/"
  :wot "https://www.w3.org/2019/wot/security#"
  :defend "https://d3fend.mitre.org/ontologies/d3fend#"
)

(define-graph harvesting ("http://mu.semte.ch/graphs/harvesting")
  ("tasks:Task" -> _ )
  ("cogs:Job" -> _ )
  ("cogs:ScheduledJob" -> _ )
  ("tasks:ScheduledTask" -> _ )
  ("tasks:CronSchedule" -> _ )
  ("schema:repeatFrequency" -> _ )
  ("core:Error" -> _ )
  ("harvesting:HarvestingCollection" -> _ )
  ("nfo:RemoteDataObject" -> _ )
  ("nfo:FileDataObject" -> _ )
  ("nfo:DataContainer" -> _ )
  ("ndo:DownloadEvent" -> _ )
  ("dcat:Dataset" -> _ )
  ("dcat:Distribution" -> _ )
  ("dcat:Catalog" -> _ )
  ("security:AuthenticationConfiguration" -> _ )
  ("security:Credentials" -> _ )
  ("security:BasicAuthenticationCredentials" -> _ )
  ("security:OAuth2Credentials" -> _ )
  ("wot:SecurityScheme" -> _ )
  ("wot:BasicSecurityScheme" -> _ )
  ("wot:OAuth2SecurityScheme" -> _ ))

(define-graph harvesting-public ("http://mu.semte.ch/graphs/harvesting")
  ("nfo:RemoteDataObject" -> _)
  ("nfo:FileDataObject" -> _))

(define-graph public ("http://mu.semte.ch/graphs/public")
  ("besluit:Bestuurseenheid" -> _)
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

(grant (read)
      :to harvesting-public
      :for "public")

(grant (read)
      :to harvesting
      :for "logged-in")

(supply-allowed-group "logged-in"
  :query "PREFIX session: <http://mu.semte.ch/vocabularies/session/>
      SELECT DISTINCT ?account WHERE {
      <SESSION_ID> session:account ?account.
      }")