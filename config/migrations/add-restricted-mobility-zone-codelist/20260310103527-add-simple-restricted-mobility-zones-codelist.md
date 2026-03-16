
prefix skos: <http://www.w3.org/2004/02/skos/core#>
prefix mu: <http://mu.semte.ch/vocabularies/core/>

CONSTRUCT {
    <http://data.lblod.gift/id/conceptscheme/restricted-mobility-zone-simple> a skos:ConceptScheme ;
        mu:uuid "5490f09a-49b9-44fd-8203-d0801699e779" ;
        skos:prefLabel "Simpele lijst van beperkte mobiliteitszone"@nl ;
        skos:definition """Lijst met 1 concept van beperkte mobiliteitszone waarbij de lijst van types van beperkte mobiliteitszones gebruikt wordt als definitie."""@nl .

    <https://data.vlaanderen.be/id/concept/ZoneType/fc17fa1b-9b61-4396-a609-845643b3b865> a skos:Concept ;
        mu:uuid "fc17fa1b-9b61-4396-a609-845643b3b865";
        skos:prefLabel "Restrictive mobility zone"@en, "Beperkte mobiliteitszone"@nl ;
        skos:definition ?finalDefinitionEn, ?finalDefinitionNl ;
        skos:topConceptOf <http://data.lblod.gift/id/conceptscheme/restricted-mobility-zone-simple> ;
        skos:inScheme <http://data.lblod.gift/id/conceptscheme/restricted-mobility-zone-simple> .
}
where {
  graph <http://mu.semte.ch/graphs/public> {
    {
        select distinct (group_concat(?labelAndDefinition ; separator='; ') as ?concatLabelAndDefinitionEn)
        where {
        ?concept skos:prefLabel ?label ;
                skos:definition ?definition ;
                    skos:inScheme
            <http://data.lblod.gift/id/conceptscheme/restricted-mobility-zone-types> .
        
        FILTER NOT EXISTS {
          {
          	?brederConcept skos:narrower ?concept .
    	  } UNION {
        	?concept skos:broader ?brederConcept .
          }
        }
        
        BIND (IF(?label != ?definition, concat(str(?label), ': ', str(?definition)), str(?label)) as ?labelAndDefinition)
        FILTER (lang(?label) = 'en')
        FILTER (lang(?definition) = 'en')
        }
    }
        
    BIND(strlang(concat("This is an non-exhaustive list of restricted mobility zones: ", str(?concatLabelAndDefinitionEn)), 'en') as ?finalDefinitionEn)
    
    {
        select DISTINCT (group_concat(?labelAndDefinition ; separator='; ') as ?concatLabelAndDefinitionNl)
        where {
        ?concept skos:prefLabel ?label ;
                skos:definition ?definition ;
                    skos:inScheme
            <http://data.lblod.gift/id/conceptscheme/restricted-mobility-zone-types> .
        
        FILTER NOT EXISTS {
          {
          	?brederConcept skos:narrower ?concept .
    	  } UNION {
        	?concept skos:broader ?brederConcept .
          }
        }
        BIND (IF(?label != ?definition, concat(str(?label), ': ', str(?definition)), str(?label)) as ?labelAndDefinition)
        FILTER (lang(?label) = 'nl')
        FILTER (lang(?definition) = 'nl')
        }
    }
    
    BIND(strlang(concat("Dit is een niet-volledige lijst van beperkte mobiliteitszones: ", str(?concatLabelAndDefinitionNl)), 'nl') as ?finalDefinitionNl)
  }
}