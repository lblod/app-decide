# Example SPARQL queries (themes & geo) — Gent

This document collects ready-to-run SPARQL examples against the DECIDe triple
store. The geo queries below are scoped to **Gent**: the reference point and the
neighbourhood polygon use Gent coordinates.

## Endpoint

```
https://ds.decide.lblod.info/api/sparql
```


## Theme queries

### How many decisions per SDG theme

```sparql
PREFIX oa:   <http://www.w3.org/ns/oa#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

SELECT ?theme (COUNT(DISTINCT ?expression) AS ?count_annotation) WHERE {
  ?annotation a oa:Annotation ;
       oa:motivatedBy oa:classifying ;
       oa:hasBody     ?concept ;
       oa:hasTarget   ?expression .
  ?concept skos:inScheme <http://data.lblod.gift/id/conceptscheme/sdg-simple> ;
           skos:prefLabel ?theme .
}
GROUP BY ?theme
ORDER BY DESC(?count_annotation)
```

### Decisions classified under one specific theme

```sparql
PREFIX oa:   <http://www.w3.org/ns/oa#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX eli:  <http://data.europa.eu/eli/ontology#>
PREFIX nif:  <http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#>

SELECT ?work ?theme WHERE {
  ?annotation a oa:Annotation ;
       oa:motivatedBy oa:classifying ;
       oa:hasBody     ?concept ;
       oa:hasTarget   ?expression .
  ?concept skos:inScheme <http://data.lblod.gift/id/conceptscheme/sdg-simple> ;
           skos:prefLabel ?theme ;
           skos:notation  13 .   # SDG 13 Climate action
  ?expression eli:realizes ?work .
}
```

## Geo queries

> [!IMPORTANT]
> **Coordinate order: latitude first, then longitude.** The geocoded data is
> stored in `POINT(lat lon)` axis order (e.g. `POINT(51.0536 3.7228)`), so write
> your reference point and polygon vertices the same way. Use
> `51.03288860208872 3.720601092700513` — **not** the reversed
> `3.720601092700513 51.03288860208872`. Passing them in the opposite order to
> the data silently returns wrong or empty results.

### Distance to a point - decisions nearest a location

```sparql
PREFIX rdf:       <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dct:       <http://purl.org/dc/terms/>
PREFIX locn:      <http://www.w3.org/ns/locn#>
PREFIX rdfs:      <http://www.w3.org/2000/01/rdf-schema#>
PREFIX geosparql: <http://www.opengis.net/ont/geosparql#>
PREFIX bif:       <bif:>
PREFIX prov:      <http://www.w3.org/ns/prov#>
PREFIX oa:        <http://www.w3.org/ns/oa#>
PREFIX eli:       <http://data.europa.eu/eli/ontology#>
PREFIX task: <http://redpencil.data.gift/vocabularies/tasks/>

SELECT DISTINCT ?work ?locationLabel ?dist
WHERE {
  ?task task:operation <http://lblod.data.gift/id/jobs/concept/TaskOperation/entity-extracting> .
  ?task prov:generated / oa:hasBody ?st .
  ?st rdf:subject   ?work ;
      rdf:predicate prov:atLocation ;
      rdf:object    ?location .

  ?work a eli:Work .

  ?location a dct:Location ;
       rdfs:label ?locationLabel ;
       locn:geometry/geosparql:asWKT ?wkt .

  FILTER(!STRSTARTS(STR(?wkt), "SRID"))

  BIND(
    bif:st_distance(
      ?wkt,
      "POINT(51.0536 3.7228)"^^geosparql:wktLiteral
    ) AS ?dist
  )
}
ORDER BY ?dist
LIMIT 10
```
### Radius filter ("everything within 2 km of a point").

```sparql
PREFIX bif:       <bif:>
PREFIX rdf:       <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dct:       <http://purl.org/dc/terms/>
PREFIX locn:      <http://www.w3.org/ns/locn#>
PREFIX rdfs:      <http://www.w3.org/2000/01/rdf-schema#>
PREFIX geosparql: <http://www.opengis.net/ont/geosparql#>
PREFIX prov:      <http://www.w3.org/ns/prov#>
PREFIX oa:        <http://www.w3.org/ns/oa#>
PREFIX eli:       <http://data.europa.eu/eli/ontology#>
PREFIX task: <http://redpencil.data.gift/vocabularies/tasks/>

SELECT DISTINCT ?work ?locationLabel ?wkt ?dist
WHERE {
  ?task task:operation <http://lblod.data.gift/id/jobs/concept/TaskOperation/entity-extracting> .
  ?task prov:generated / oa:hasBody ?st .
  ?st rdf:subject   ?work ;
      rdf:predicate prov:atLocation ;
      rdf:object    ?location .

  ?work a eli:Work .

  ?location a dct:Location ;
            rdfs:label ?locationLabel ;
            locn:geometry ?geometry .

  ?geometry geosparql:asWKT ?wkt .

  FILTER(!STRSTARTS(STR(?wkt), "SRID"))

  BIND(bif:st_geomfromtext(str(?wkt)) AS ?g)
  BIND(bif:st_geomfromtext("POINT(51.0536 3.7228)") AS ?point)

  FILTER(bif:st_intersects(?g, ?point, 2))

  BIND(bif:st_distance(?g, ?point) AS ?dist)
}
ORDER BY ?dist
LIMIT 10
```

### Overlap with a neighbourhood polygon

Find every decision whose location falls inside a neighbourhood.

```sparql
PREFIX bif: <bif:>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX locn: <http://www.w3.org/ns/locn#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX geosparql: <http://www.opengis.net/ont/geosparql#>
PREFIX prov:      <http://www.w3.org/ns/prov#>
PREFIX oa:        <http://www.w3.org/ns/oa#>
PREFIX eli:       <http://data.europa.eu/eli/ontology#>
PREFIX task: <http://redpencil.data.gift/vocabularies/tasks/>

SELECT DISTINCT ?work ?locationLabel ?wkt WHERE {
  BIND("POLYGON((51.03288860208872 3.720601092700513, 51.03224135651627 3.723548234712275, 51.03171283287891 3.726355384415909, 51.03154718710846 3.727301396943684, 51.03141894427892 3.72851490214217, 51.031414714600764 3.729889226769707, 51.031429345448586 3.73026680825023, 51.031467190038654 3.731279886751365, 51.0316311381827 3.732507944696405, 51.03188479924819 3.733538062582221, 51.03214574191736 3.734586625904459, 51.0323624395222 3.734429727382551, 51.03253078220004 3.734307696898604, 51.032983988943236 3.734167552384262, 51.03384617228757 3.734020440834219, 51.03409520519079 3.733858818951153, 51.03427328880832 3.733709562096008, 51.034335948374775 3.733660240088316, 51.03504675957946 3.733114545521163, 51.03514245400401 3.733023428499061, 51.03517733297453 3.732990164235771, 51.03537416757013 3.73265102702356, 51.03578532221473 3.732214878932431, 51.03590059080501 3.732086423901174, 51.036331279494256 3.731605802510063, 51.03674334442199 3.731172475384089, 51.037644563290456 3.730266251975765, 51.03808591215012 3.729929455380415, 51.03832673338823 3.729746522006495, 51.038447716980045 3.72967785963219, 51.03851185825477 3.726592970189707, 51.03855153245631 3.725625730160073, 51.0390273816737 3.724695268037407, 51.040137461785385 3.722541229283754, 51.04137866261023 3.720208462860556, 51.04200170479091 3.719080498787271, 51.04273551161214 3.71766435327637, 51.04268900029618 3.717543795215513, 51.04260965717662 3.717338137899933, 51.042588676096806 3.717282818293798, 51.04150787827815 3.715120498727255, 51.04135932087231 3.714592138636433, 51.04132148309328 3.714253304514827, 51.04136193249667 3.713929061721432, 51.04140913253875 3.713687425882593, 51.04165093665232 3.71320066465304, 51.04180164712024 3.712983244247412, 51.042273392269784 3.712302181401332, 51.042551033845214 3.71179493849089, 51.04280375949535 3.7113336691443, 51.04283191085177 3.711223476891918, 51.04285217116675 3.711149043740167, 51.04286185187559 3.711111833447879, 51.0428785643954 3.711046005639363, 51.043149626840425 3.710005536290441, 51.04319524249006 3.709642703679901, 51.04323228309058 3.70935414049947, 51.04328325414853 3.706739651282017, 51.04328531020429 3.706625545966262, 51.0432939144469 3.706556978606727, 51.043348982256504 3.706118432077654, 51.04342438543548 3.705619706498465, 51.04349826948029 3.705330616928767, 51.04415010561003 3.702798828814457, 51.04416312137997 3.702715936938112, 51.044187459758184 3.702568714878503, 51.044355094391044 3.701532491085743, 51.044414193664615 3.701015441612768, 51.04440039726207 3.700167175157725, 51.044266122935134 3.698841499626723, 51.04416091358682 3.698361022146217, 51.04412860211853 3.698211756502067, 51.0441009226448 3.698086666412565, 51.044037246367445 3.697796678389544, 51.04356723033359 3.696713972709801, 51.04352987314563 3.696626098840129, 51.04324411399715 3.696171040791673, 51.04312903138926 3.696010134371288, 51.04294870977401 3.695758905163952, 51.04239381057919 3.694927003418193, 51.042079870207246 3.694418187313042, 51.041817268737226 3.693927175449916, 51.04155515568761 3.693364866880333, 51.04151231295481 3.693261393583441, 51.041340001377314 3.692840386362687, 51.04115333105698 3.692423867143301, 51.04084002484567 3.691870869667355, 51.04053235710296 3.691517420136297, 51.04020725185499 3.691258334296047, 51.03982456974458 3.690991529717437, 51.03965780510108 3.690911242730243, 51.03951087271759 3.690840650284399, 51.039464000785706 3.690818514945477, 51.0392520557479 3.691792573608213, 51.03899317416933 3.692891347200946, 51.0388527877606 3.69349221666624, 51.038694036176395 3.694183173277708, 51.03867209487254 3.694276167102986, 51.03854041859877 3.694986690370579, 51.038439082898655 3.695501438154632, 51.038293192360044 3.696085261858926, 51.03813773654063 3.69672625099915, 51.03799413293183 3.69739700769333, 51.03779962415766 3.698285208507863, 51.03750124481667 3.699562697714813, 51.03678462346351 3.702866427927245, 51.035920386305655 3.706632653217466, 51.03564886183867 3.707745700106784, 51.035528546211 3.708252100880717, 51.03393225900353 3.715713731230408, 51.03288860208872 3.720601092700513))"^^geosparql:wktLiteral AS ?polygon)

  ?task task:operation <http://lblod.data.gift/id/jobs/concept/TaskOperation/entity-extracting> .
  ?task prov:generated / oa:hasBody ?st .
  ?st a rdf:Statement ;
  rdf:subject ?work ;
  rdf:predicate prov:atLocation ;
  rdf:object ?location .

  ?work a eli:Work .

  ?location a dct:Location ;
  rdfs:label ?locationLabel ;
  locn:geometry ?geometry .

  ?geometry geosparql:asWKT ?wkt .
  FILTER(!STRSTARTS(STR(?wkt), "SRID"))

  FILTER(bif:st_intersects(?wkt, ?polygon))
} LIMIT 10
```
