(in-package :acl)

(define-prefixes
  :sh "http://www.w3.org/ns/shacl#"
  :wot "https://www.w3.org/2019/wot/security#"
  :wikidata "http://www.wikidata.org/entity/"
  :vcard "http://www.w3.org/2006/vcard/ns#"
  :tasks "http://redpencil.data.gift/vocabularies/tasks/"
  :skos "http://www.w3.org/2004/02/skos/core#"
  :security "http://lblod.data.gift/vocabularies/security/"
  :schema "http://schema.org/"
  :person "http://www.w3.org/ns/person#"
  :perceel "https://data.vlaanderen.be/ns/perceel#"
  :org "http://www.w3.org/ns/org#"
  :oparl-temp "http://mu.semte.ch/vocabularies/ext/oparl/"
  :odrl "http://www.w3.org/ns/odrl/2/"
  :oa "http://www.w3.org/ns/oa#"
  :nfo "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#"
  :ndo "http://oscaf.sourceforge.net/ndo.html#"
  :mandaat "http://data.vlaanderen.be/ns/mandaat#"
  :locn "http://www.w3.org/ns/locn#"
  :harvesting "http://lblod.data.gift/vocabularies/harvesting/"
  :generiek "https://data.vlaanderen.be/ns/generiek#"
  :foaf "http://xmlns.com/foaf/0.1/"
  :ext "http://mu.semte.ch/vocabularies/ext/"
  :eli-dl "http://data.europa.eu/eli/eli-draft-legislation-ontology#"
  :eli "http://data.europa.eu/eli/ontology#"
  :defend "https://d3fend.mitre.org/ontologies/d3fend#"
  :dct "http://purl.org/dc/terms/"
  :dcat "http://www.w3.org/ns/dcat#"
  :core "http://open-services.net/ns/core#"
  :cogs "http://vocab.deri.ie/cogs#"
  :cms "http://mu.semte.ch/vocabulary/cms/"
  :besluit "http://data.vlaanderen.be/ns/besluit#"
  :adms "http://www.w3.org/ns/adms#"
  :rm "http://mu.semte.ch/vocabularies/logical-delete/"
  :typedLiterals "http://mu.semte.ch/vocabularies/typed-literals/"
  :mu "http://mu.semte.ch/vocabularies/core/"
  :xsd "http://www.w3.org/2001/XMLSchema#"
  :app "http://mu.semte.ch/app/"
  :owl "http://www.w3.org/2002/07/owl#"
  :rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#")

;; Graphs
(define-graph organization ("http://mu.semte.ch/graphs/organizations/")
  ("foaf:OnlineAccount" -> _)
  ("foaf:Person" -> _)
  ("adms:Identifier" -> _))

(define-graph harvested-gent ("http://mu.semte.ch/graphs/public/gent")
  ("eli:Expression" -> _)
  ("org:Organization" -> _)
  ("eli:Manifestation" -> _)
  ("eli-dl:Activity" -> _)
  ("nfo:FileDataObject" -> _)
  ("eli:Work" -> _)
  ("nfo:RemoteDataObject" -> _))

(define-graph harvested-freiburg ("http://mu.semte.ch/graphs/public/freiburg")
  ("nfo:RemoteDataObject" -> _)
  ("eli:Expression" -> _)
  ("org:Organization" -> _)
  ("eli:Manifestation" -> _)
  ("nfo:FileDataObject" -> _)
  ("eli:Work" -> _)
  ("eli-dl:Activity" -> _))

;; This asset collection contains all information that is available to the public in the context of the DECIDe app.
(define-graph public ("http://mu.semte.ch/graphs/public")
  ("skos:ConceptScheme" -> _)
  ("cogs:Job" -> _)
  ("cms:Page" -> _)
  ("besluit:Bestuurseenheid" -> _)
  ("nfo:DataContainer" -> _)
  ("eli-dl:LegislativeProcess" -> _)
  ("dct:PeriodOfTime" -> _)
  ("foaf:Person" -> _)
  ("dcat:Catalog" -> _)
  ("locn:Address" -> _)
  ("dcat:Dataset" -> _)
  ("oa:SpecificResource" -> _)
  ("dct:Location" -> _)
  ("oparl-temp:Location" -> _)
  ("eli-dl:ParliamentaryTerm" -> _)
  ("dct:MediaTypeOrExtent" -> _)
  ("tasks:Task" -> _)
  ("perceel:Perceel" -> _)
  ("eli-dl:LegislativeProcessWork" -> _)
  ("eli-dl:Decision" -> _)
  ("schema:TouristAttraction" -> _)
  ("eli-dl:Vote" -> _)
  ("wikidata:Q2785216" -> _)
  ("org:Organization" -> _)
  ("schema:repeatFrequency" -> _)
  ("eli:Expression" -> _)
  ("oa:Annotation" -> _)
  ("eli:LegalExpression" -> _)
  ("locn:Geometry" -> _)
  ("oa:TextPositionSelector" -> _)
  ("eli:Manifestation" -> _)
  ("eli-dl:ForeseenActivity" -> _)
  ("eli-dl:Participation" -> _)
  ("org:Membership" -> _)
  ("eli-dl:DraftLegislationWork" -> _)
  ("dcat:Distribution" -> _)
  ("skos:Concept" -> _)
  ("cogs:ScheduledJob" -> _)
  ("ext:AnnotationJob" -> _)
  ("eli-dl:Activity" -> _)
  ("eli:Work" -> _)
  ("tasks:CronSchedule" -> _)
  ("eli-dl:ProcessStage" -> _)
  ("foaf:Agent" -> _)
  ("eli:ComplexWork" -> _)
  ("tasks:ScheduledTask" -> _))

(define-graph harvested-pdf ("http://mu.semte.ch/graphs/public/pdf")
  ("org:Organization" -> _)
  ("eli:Expression" -> _)
  ("eli:Manifestation" -> _)
  ("eli-dl:Activity" -> _)
  ("eli:Work" -> _)
  ("nfo:FileDataObject" -> _)
  ("nfo:RemoteDataObject" -> _))

;; This asset collection contains all information that is available in as part the harvesting done by the DECIDE app.
(define-graph harvesting ("http://mu.semte.ch/graphs/harvesting")
  ("wot:BasicSecurityScheme" -> _)
  ("cogs:Job" -> _)
  ("security:Credentials" -> _)
  ("ndo:DownloadEvent" -> _)
  ("nfo:DataContainer" -> _)
  ("wot:OAuth2SecurityScheme" -> _)
  ("dcat:Catalog" -> _)
  ("security:BasicAuthenticationCredentials" -> _)
  ("sh:NodeShape" -> _)
  ("dcat:Dataset" -> _)
  ("tasks:Task" -> _)
  ("harvesting:HarvestingCollection" -> _)
  ("wot:SecurityScheme" -> _)
  ("schema:repeatFrequency" -> _)
  ("security:OAuth2Credentials" -> _)
  ("security:AuthenticationConfiguration" -> _)
  ("dcat:Distribution" -> _)
  ("cogs:ScheduledJob" -> _)
  ("tasks:CronSchedule" -> _)
  ("core:Error" -> _)
  ("nfo:FileDataObject" -> _)
  ("tasks:ScheduledTask" -> _)
  ("nfo:RemoteDataObject" -> _))

(define-graph oslo-organizations ("http://mu.semte.ch/graphs/bestuurseenheden-bestuursorganen")
  ("besluit:Bestuurseenheid" -> _))

(define-graph organizations ("http://mu.semte.ch/graphs/organizations")
  ("org:Organization" -> _))


;; Groups
(supply-allowed-group "organization-member"
  :parameters ("session_group")
  :query "PREFIX ext: <http://mu.semte.ch/vocabularies/ext/>
          PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
          SELECT ?session_group ?session_role WHERE {
            <SESSION_ID> ext:sessionGroup/mu:uuid ?session_group.
          }")

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
  :to-graph organization
  :for-allowed-group "organization-member")

(grant (read)
  :to-graph harvested-gent
  :for-allowed-group "public")

(grant (read)
  :to-graph harvested-freiburg
  :for-allowed-group "public")

(grant (read)
  :to-graph public
  :for-allowed-group "public")

(grant (read)
  :to-graph harvested-pdf
  :for-allowed-group "public")

(grant (read write)
  :to-graph harvesting
  :for-allowed-group "logged-in")

(grant (read)
  :to-graph oslo-organizations
  :for-allowed-group "public")

(grant (read)
  :to-graph organizations
  :for-allowed-group "public")

