(in-package :acl)

(define-prefixes
  :adms "http://www.w3.org/ns/adms#"
  :besluit "http://data.vlaanderen.be/ns/besluit#"
  :cms "http://mu.semte.ch/vocabulary/cms/"
  :cogs "http://vocab.deri.ie/cogs#"
  :core "http://open-services.net/ns/core#"
  :dcat "http://www.w3.org/ns/dcat#"
  :dct "http://purl.org/dc/terms/"
  :defend "https://d3fend.mitre.org/ontologies/d3fend#"
  :eli "http://data.europa.eu/eli/ontology#"
  :eli-dl "http://data.europa.eu/eli/eli-draft-legislation-ontology#"
  :ext "http://mu.semte.ch/vocabularies/ext/"
  :foaf "http://xmlns.com/foaf/0.1/"
  :generiek "https://data.vlaanderen.be/ns/generiek#"
  :harvesting "http://lblod.data.gift/vocabularies/harvesting/"
  :locn "http://www.w3.org/ns/locn#"
  :mandaat "http://data.vlaanderen.be/ns/mandaat#"
  :ndo "http://oscaf.sourceforge.net/ndo.html#"
  :nfo "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#"
  :oa "http://www.w3.org/ns/oa#"
  :oparl-temp "http://mu.semte.ch/vocabularies/ext/oparl/"
  :org "http://www.w3.org/ns/org#"
  :perceel "https://data.vlaanderen.be/ns/perceel#"
  :person "http://www.w3.org/ns/person#"
  :schema "http://schema.org/"
  :security "http://lblod.data.gift/vocabularies/security/"
  :skos "http://www.w3.org/2004/02/skos/core#"
  :tasks "http://redpencil.data.gift/vocabularies/tasks/"
  :wikidata "http://www.wikidata.org/entity/"
  :wot "https://www.w3.org/2019/wot/security#"
  :sh "http://www.w3.org/ns/shacl#")

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
  ("wot:OAuth2SecurityScheme" -> _ )
  ("sh:NodeShape" -> _ ))

(define-graph organizations ("http://mu.semte.ch/graphs/organizations")
  ("org:Organization" -> _)
)

(define-graph harvested-freiburg ("http://mu.semte.ch/graphs/public/freiburg")
  ("nfo:RemoteDataObject" -> _)
  ("nfo:FileDataObject" -> _)
  ("org:Organization" -> _)
  ("eli-dl:Activity" -> _)
  ("eli:Expression" -> _)
  ("eli:Manifestation" -> _)
  ("eli:Work" -> _))

(define-graph harvested-gent ("http://mu.semte.ch/graphs/public/gent")
  ("nfo:RemoteDataObject" -> _)
  ("nfo:FileDataObject" -> _)
  ("org:Organization" -> _)
  ("eli-dl:Activity" -> _)
  ("eli:Expression" -> _)
  ("eli:Manifestation" -> _)
  ("eli:Work" -> _))

(define-graph harvested-pdf ("http://mu.semte.ch/graphs/public/pdf")
  ("nfo:RemoteDataObject" -> _)
  ("nfo:FileDataObject" -> _)
  ("org:Organization" -> _)
  ("eli-dl:Activity" -> _)
  ("eli:Expression" -> _)
  ("eli:Manifestation" -> _)
  ("eli:Work" -> _))

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
  ;; Geo data
  ("dct:Location" -> _)
  ("locn:Geometry" -> _)
  ("locn:Address" -> _)
  ("schema:TouristAttraction" -> _)
  ("perceel:Perceel" -> _)
  ("wikidata:Q2785216" -> _)
  ;; Annotations
  ("oa:Annotation" -> _)
  ("oa:SpecificResource" -> _)
  ("oa:TextPositionSelector" -> _)
  ;; Jobs & tasks
  ("cogs:Job" -> _)
  ("ext:AnnotationJob" -> _)
  ("tasks:Task" -> _)
  ("nfo:DataContainer" -> _)
  ("cogs:ScheduledJob" -> _ )
  ("tasks:ScheduledTask" -> _ )
  ("tasks:CronSchedule" -> _ )
  ("schema:repeatFrequency" -> _ ))

(define-graph organization ("http://mu.semte.ch/graphs/organizations/")
  ("foaf:Person" -> _)
  ("foaf:OnlineAccount" -> _)
  ("adms:Identifier" -> _))

(supply-allowed-group "public")

(grant (read)
       :to-graph public
       :for-allowed-group "public")

(grant (read)
       :to-graph organizations
       :for-allowed-group "public")

(grant (read)
       :to-graph harvested-freiburg
       :for-allowed-group "public")

(grant (read)
       :to-graph harvested-gent
       :for-allowed-group "public")

(grant (read)
       :to-graph harvested-pdf
       :for-allowed-group "public")

(grant (read write)
       :to harvesting
       :for "logged-in")

(supply-allowed-group "logged-in"
                      :query "PREFIX session: <http://mu.semte.ch/vocabularies/session/>
      SELECT DISTINCT ?account WHERE {
      <SESSION_ID> session:account ?account.
      }")

(supply-allowed-group "organization-member"
  :parameters ("session_group")
  :query "PREFIX ext: <http://mu.semte.ch/vocabularies/ext/>
          PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
          SELECT ?session_group ?session_role WHERE {
            <SESSION_ID> ext:sessionGroup/mu:uuid ?session_group.
          }")

(grant (read)
       :to-graph organization
       :for-allowed-group "organization-member")

;; TODO: Is this supposed to be the final graph?
;; NOTE (10/02/2026): Graphs <http://mu.semte.ch/graphs/organizations> does NOT contain the
;; `besluit:Bestuurseenheid' type (only `org:Organization'), used that one causes resource service
;; to bug out
(define-graph organizations ("http://mu.semte.ch/graphs/bestuurseenheden-bestuursorganen")
  ("besluit:Bestuurseenheid" -> _))

(grant (read)
       :to-graph organizations
       :for-allowed-group "public")
