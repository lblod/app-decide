# Usage

Migration `20260112102218-sdg-codelist.ttl` is a full-blown codelist of SDGs, targets and indicators.
To generate a simplified SKOS codelist from this list, do following steps:

```
cd path/to/add-sdg-codelist
http-server
```

Note: http-server can be used for hosting the TTL file (`npm install -g http-server`)

Go to Comunica `https://query.comunica.dev/`
Add datasource: `http://localhost:8080/20260112102218-sdg-codelist.ttl`

Run following query:
```
prefix skos: <http://www.w3.org/2004/02/skos/core#>
prefix mu: <http://mu.semte.ch/vocabularies/core/>
prefix sdgo: <http://metadata.un.org/sdg/ontology#>

CONSTRUCT {
    ?scheme a skos:ConceptScheme ;
        mu:uuid "785cfa4d-6d74-46ad-a99c-1acc176db89e" ;
        skos:prefLabel "Simpele lijst van Sustainable Development Goals"@nl ;
        skos:definition """Bevat enkel de hoofd SDG's en waarbij de targets als definitie gebruikt worden."""@nl .

    ?newTopConcept a skos:Concept ;
        mu:uuid ?uuid;
        skos:prefLabel ?topConceptLabel ;
        skos:definition ?finalDefinition ;
        skos:topConceptOf <http://data.lblod.gift/id/conceptscheme/sdg-simple> ;
        skos:inScheme <http://data.lblod.gift/id/conceptscheme/sdg-simple> .
}
where {
    {
        select DISTINCT ?topConcept (group_concat(?targetLabel ; separator='; ') as ?concatTargetLabel)
        where {
            <http://metadata.un.org/sdg> skos:hasTopConcept ?topConcept .

            ?topConcept sdgo:hasTarget ?target .
            
            ?target skos:prefLabel ?targetLabel .
            FILTER (lang(?targetLabel) = 'en')
        }
        group by ?topConcept
    }
 
    ?topConcept skos:prefLabel ?topConceptLabel ;
            skos:note ?note .
    {
      SELECT ?scheme
      WHERE {
        BIND(<http://data.lblod.gift/id/conceptscheme/sdg-simple> AS ?scheme)
      }
      LIMIT 1
    }
    
    FILTER(lang(?topConceptLabel) = 'en')
	  FILTER(lang(?note) = 'en')
  
  	BIND(MD5(str(?concatTargetLabel)) as ?uuid)
    BIND(IRI(concat(str(?topConcept), '/', ?uuid)) as ?newTopConcept)
    BIND(strlang(concat("Targets of ", str(?note), ': ', str(?concatTargetLabel)), 'en') as ?finalDefinition)
}
```