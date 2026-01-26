(in-package :acl)

(define-prefixes
  :wot "https://www.w3.org/2019/wot/security#"
  :wikidata "http://www.wikidata.org/entity/"
  :vcard "http://www.w3.org/2006/vcard/ns#"
  :tasks "http://redpencil.data.gift/vocabularies/tasks/"
  :skos "http://www.w3.org/2004/02/skos/core#"
  :security "http://lblod.data.gift/vocabularies/security/"
  :perceel "https://data.vlaanderen.be/ns/perceel#"
  :org "http://www.w3.org/ns/org#"
  :oparl-temp "http://mu.semte.ch/vocabularies/ext/oparl/"
  :odrl "http://www.w3.org/ns/odrl/2/"
  :oa "http://www.w3.org/ns/oa#"
  :sh "http://www.w3.org/ns/shacl#"
  :schema "http://schema.org/"
  :nfo "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#"
  :ndo "http://oscaf.sourceforge.net/ndo.html#"
  :locn "http://www.w3.org/ns/locn#"
  :foaf "http://xmlns.com/foaf/0.1/"
  :harvesting "http://lblod.data.gift/vocabularies/harvesting/"
  :ext "http://mu.semte.ch/vocabularies/ext/"
  :eli-dl "http://data.europa.eu/eli/eli-draft-legislation-ontology#"
  :eli "http://data.europa.eu/eli/ontology#"
  :dct "http://purl.org/dc/terms/"
  :dcat "http://www.w3.org/ns/dcat#"
  :core "http://open-services.net/ns/core#"
  :cogs "http://vocab.deri.ie/cogs#"
  :cms "http://mu.semte.ch/vocabulary/cms/"
  :besluit "http://data.vlaanderen.be/ns/besluit#"
  :rm "http://mu.semte.ch/vocabularies/logical-delete/"
  :typedLiterals "http://mu.semte.ch/vocabularies/typed-literals/"
  :mu "http://mu.semte.ch/vocabularies/core/"
  :xsd "http://www.w3.org/2001/XMLSchema#"
  :app "http://mu.semte.ch/app/"
  :owl "http://www.w3.org/2002/07/owl#"
  :rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#")

;; Graphs
;; This asset collection contains all information that is available to public as part of the harvesting done by the DECIDE app.
(define-graph harvesting-public ("http://mu.semte.ch/graphs/harvesting")
  ("nfo:RemoteDataObject" -> _)
  ("nfo:FileDataObject" -> _)
  ("eli:Expression" -> _)
  ("eli:LegalExpression" -> _)
  ("eli:Manifestation" -> _)
  ("eli-dl:Activity" -> _))

;; This asset collection contains all information that is available in as part the harvesting done by the DECIDE app.
(define-graph harvesting ("http://mu.semte.ch/graphs/harvesting")
  ("core:Error" -> _)
  ("dcat:Catalog" -> _)
  ("cogs:Job" -> _)
  ("nfo:DataContainer" -> _)
  ("wot:SecurityScheme" -> _)
  ("dcat:Dataset" -> _)
  ("cogs:ScheduledJob" -> _)
  ("nfo:FileDataObject" -> _)
  ("wot:OAuth2SecurityScheme" -> _)
  ("tasks:CronSchedule" -> _)
  ("security:OAuth2Credentials" -> _)
  ("security:BasicAuthenticationCredentials" -> _)
  ("tasks:Task" -> _)
  ("security:AuthenticationConfiguration" -> _)
  ("schema:repeatFrequency" -> _)
  ("nfo:RemoteDataObject" -> _)
  ("harvesting:HarvestingCollection" -> _)
  ("wot:BasicSecurityScheme" -> _)
  ("tasks:ScheduledTask" -> _)
  ("security:Credentials" -> _)
  ("ndo:DownloadEvent" -> _)
  ("dcat:Distribution" -> _))

;; This asset collection contains all information that is available to the public in the context of the DECIDe app.
(define-graph public ("http://mu.semte.ch/graphs/public")
  ("eli-dl:Decision" -> _)
  ("locn:Address" -> _)
  ("locn:Geometry" -> _)
  ("oparl-temp:Location" -> _)
  ("org:Membership" -> _)
  ("dct:PeriodOfTime" -> _)
  ("dcat:Catalog" -> _)
  ("eli-dl:LegislativeProcessWork" -> _)
  ("dct:Location" -> _)
  ("oa:TextPositionSelector" -> _)
  ("eli-dl:Participation" -> _)
  ("schema:TouristAttraction" -> _)
  ("eli:LegalExpression" -> _)
  ("eli:ComplexWork" -> _)
  ("oa:Annotation" -> _)
  ("dcat:Dataset" -> _)
  ("eli:Work" -> _)
  ("wikidata:Q2785216" -> _)
  ("eli-dl:Vote" -> _)
  ("skos:Concept" -> _)
  ("org:Organization" -> _)
  ("eli:Expression" -> _)
  ("cms:Page" -> _)
  ("eli-dl:ForeseenActivity" -> _)
  ("besluit:Bestuurseenheid" -> _)
  ("eli-dl:DraftLegislationWork" -> _)
  ("eli-dl:Activity" -> _)
  ("eli-dl:ProcessStage" -> _)
  ("oa:SpecificResource" -> _)
  ("eli-dl:ParliamentaryTerm" -> _)
  ("skos:ConceptScheme" -> _)
  ("foaf:Agent" -> _)
  ("dcat:Distribution" -> _)
  ("perceel:Perceel" -> _)
  ("foaf:Person" -> _)
  ("dct:MediaTypeOrExtent" -> _)
  ("eli-dl:LegislativeProcess" -> _)
  ("eli:Manifestation" -> _))


;; Groups
;; This represents all logged in users of the system.
(supply-allowed-group "logged-in"
  :query "PREFIX session: <http://mu.semte.ch/vocabularies/session/>
  SELECT DISTINCT ?account
  WHERE {
    <SESSION_ID> session:account ?account .
  }")

;; This party represent all (possibly not logged in) users of the system.
(supply-allowed-group "public")


;; Grants
(grant (read)
  :to-graph harvesting-public
  :for-allowed-group "public")

(grant (write read)
  :to-graph harvesting
  :for-allowed-group "logged-in")

(grant (read)
  :to-graph public
  :for-allowed-group "public")

