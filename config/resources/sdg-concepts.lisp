(in-package :mu-cl-resources)

(define-resource concept-scheme ()
  :class (s-prefix "skos:ConceptScheme")
  :properties `((:uuid :string ,(s-prefix "mu:uuid"))
                (:pref-label :string ,(s-prefix "skos:prefLabel"))
                (:definition :string ,(s-prefix "skos:definition")))
  :has-many `((concept :via ,(s-prefix "skos:inScheme")
                        :inverse t
                        :as "concept"))
  :features `(include-uri)
  :resource-base (s-url "http://data.lblod.gift/id/conceptscheme/")
  :on-path "sdg-concept-schemes")

(define-resource concept ()
  :class (s-prefix "skos:Concept")
  :properties `((:uuid :string ,(s-prefix "mu:uuid"))
                (:pref-label :string ,(s-prefix "skos:prefLabel"))
                (:alt-label :string ,(s-prefix "skos:altLabel"))
                (:definition :string ,(s-prefix "skos:definition"))
                (:notation :string ,(s-prefix "skos:notation"))
                )
  :has-one `((concept-scheme :via ,(s-prefix "skos:inScheme")
                             :as "concept-scheme"))
  :features `(include-uri)
  :resource-base (s-url "http://data.lblod.gift/id/concept/")
  :on-path "sdg-concepts")


