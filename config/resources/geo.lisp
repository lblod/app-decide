(in-package :mu-cl-resources)

(define-resource address ()
  :class (s-prefix "locn:Address")
  :properties `((:exact-match :url ,(s-prefix "skos:exactMatch")))
  :has-one `((geometry :via ,(s-prefix "locn:geometry")
                       :as "geometry"))
  :resource-base (s-url "http://data.lblod.info/id/adresses/"))

(define-resource location ()
  :class (s-prefix "dct:Location")
  :properties `((:label :string ,(s-prefix "rdfs:label"))
                (:exact-match :url ,(s-prefix "skos:exactMatch")))
  :has-one `((geometry :via ,(s-prefix "locn:geometry")
                       :as "geometry"))
  :resource-base (s-url "http://data.lblod.info/id/locations/")
  :on-path "locations")

(define-resource geometry ()
  :class (s-prefix "locn:Geometry")
  :properties `((:as-wkt :url ,(s-prefix "geosparql:asWKT")))
  :resource-base (s-url "http://data.lblod.info/id/locations/geometry/")
  :on-path "geometries")

;; TODO: Add: `schema:TouristAttraction', `Perceel:Perceel', and `wikidata:Q2785216'?
