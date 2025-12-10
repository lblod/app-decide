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
;; This asset collection contains all information that is available to the public in the context of the DECIDe app.
(define-graph public ("http://mu.semte.ch/graphs/public")
  ("dcat:Distribution" -> _)
  ("eli-dl:Vote" -> _)
  ("foaf:Person" -> _)
  ("dct:PeriodOfTime" -> _)
  ("eli-dl:ParliamentaryTerm" -> _)
  ("org:Membership" -> _)
  ("wikidata:Q2785216" -> _)
  ("skos:Concept" -> _)
  ("eli-dl:Decision" -> _)
  ("schema:TouristAttraction" -> _)
  ("oa:SpecificResource" -> _)
  ("oa:Annotation" -> _)
  ("eli-dl:LegislativeProcessWork" -> _)
  ("dcat:Catalog" -> _)
  ("perceel:Perceel" -> _)
  ("skos:ConceptScheme" -> _)
  ("eli:Manifestation" -> _)
  ("foaf:Agent" -> _)
  ("eli-dl:Activity" -> _)
  ("oa:TextPositionSelector" -> _)
  ("dct:Location" -> _)
  ("locn:Geometry" -> _)
  ("locn:Address" -> _)
  ("eli:Expression" -> _)
  ("eli-dl:ProcessStage" -> _)
  ("eli:LegalExpression" -> _)
  ("eli-dl:DraftLegislationWork" -> _)
  ("dcat:Dataset" -> _)
  ("eli:ComplexWork" -> _)
  ("oparl-temp:Location" -> _)
  ("eli-dl:LegislativeProcess" -> _)
  ("eli-dl:Participation" -> _)
  ("cms:Page" -> _)
  ("eli:Work" -> _)
  ("org:Organization" -> _)
  ("besluit:Bestuurseenheid" -> _)
  ("dct:MediaTypeOrExtent" -> _)
  ("eli-dl:ForeseenActivity" -> _))

;; This asset collection contains all information that is available to public as part of the harvesting done by the DECIDE app.
(define-graph harvesting-public ("http://mu.semte.ch/graphs/harvesting")
  ("eli:Manifestation" -> _)
  ("eli-dl:Activity" -> _)
  ("eli:LegalExpression" -> _)
  ("eli:Expression" -> _)
  ("nfo:RemoteDataObject" -> _)
  ("nfo:FileDataObject" -> _))

;; This asset collection contains all information that is available in as part the harvesting done by the DECIDE app.
(define-graph harvesting ("http://mu.semte.ch/graphs/harvesting")
  ("core:Error" -> _)
  ("tasks:Task" -> _)
  ("security:AuthenticationConfiguration" -> _)
  ("nfo:RemoteDataObject" -> _)
  ("dcat:Dataset" -> _)
  ("tasks:CronSchedule" -> _)
  ("security:Credentials" -> _)
  ("harvesting:HarvestingCollection" -> _)
  ("dcat:Catalog" -> _)
  ("wot:BasicSecurityScheme" -> _)
  ("security:BasicAuthenticationCredentials" -> _)
  ("nfo:DataContainer" -> _)
  ("schema:repeatFrequency" -> _)
  ("wot:SecurityScheme" -> _)
  ("cogs:Job" -> _)
  ("cogs:ScheduledJob" -> _)
  ("security:OAuth2Credentials" -> _)
  ("nfo:FileDataObject" -> _)
  ("dcat:Distribution" -> _)
  ("tasks:ScheduledTask" -> _)
  ("wot:OAuth2SecurityScheme" -> _)
  ("ndo:DownloadEvent" -> _))


;; Groups
;; This party represent all (possibly not logged in) users of the system.
(supply-allowed-group "public-user")

;; This represents all logged in users of the system.
(supply-allowed-group "authenticated-user"
  :query "PREFIX session: <http://mu.semte.ch/vocabularies/session/>
  SELECT DISTINCT ?account
  WHERE {
    <SESSION_ID> session:account ?account .
  }")


;; Grants
(grant (read)
  :to-graph public
  :for-allowed-group "public-user")

(grant (read)
  :to-graph harvesting-public
  :for-allowed-group "public-user")

(grant (read)
  :to-graph harvesting
  :for-allowed-group "authenticated-user")

