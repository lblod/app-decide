(in-package :mu-cl-resources)

(define-resource annotation ()
  :class (s-prefix "oa:Annotation")
  :properties `((:confidence :number ,(s-prefix "nif:confidence"))
                (:motivated-by :url ,(s-prefix "oa:motivatedBy")))
  :has-one `((annotation-target :via ,(s-prefix "oa:hasTarget")
                                :as "has-target")
             (location :via ,(s-prefix "oa:hasBody")
                       :as "has-body"))
  :features '(include-uri)
  :resource-base (s-url "http://data.lblod.info/id/annotations/")
  :on-path "annotations")

(define-resource annotation-target () ;; generic resource class to serve as a target for annotations, to be extended with specific classes
  :class (s-prefix "ext:AnnotationTarget")
  :has-one `((annotation :via ,(s-prefix "oa:hasTarget")
              :as "annotations"
              :inverse t))
  :resource-base (s-url "http://data.lblod.info/id/annotation-targets/")
  :on-path "annotation-targets")

(define-resource specific-resource (annotation-target)
  :class (s-prefix "oa:SpecificResource")
  :has-one `((expression :via ,(s-prefix "oa:hasSource")
                         :as "source")
             (text-position-selector :via ,(s-prefix "oa:hasSelector")
                                     :as "selector"))
  :features '(include-uri)
  :resource-base (s-url "http://data.lblod.info/id/specific-resources/")
  :on-path "specific-resources")

(define-resource text-position-selector ()
  :class (s-prefix "oa:TextPositionSelector")
  :properties `((:start :number ,(s-prefix "oa:start"))
                (:end :number ,(s-prefix "oa:end")))
  :features '(include-uri)
  :resource-base (s-url "http://data.lblod.info/id/text-position-selectors/")
  :on-path "text-position-selectors")


(define-resource question () ;; created by the question-answering-service
  :class (s-prefix "schema:Question")
  :properties `((:created         :datetime ,(s-prefix "dct:created")) ;; timestamp of the question
                (:text            :string   ,(s-prefix "schema:text")) ;; the original question asked by the user
                (:description     :string   ,(s-prefix "dct:description"))) ;; complete prompt given to the LLM
  :has-one `((answer              :via ,(s-prefix "schema:suggestedAnswer")
                                  :as "answer"))
  :resource-base (s-url "http://data.lblod.info/id/questions/")
  :on-path "questions")

(define-resource answer (annotation-target) ;; created by the question-answering-service, amended by the frontend upon evaluation
  :class (s-prefix "schema:Answer")
  :properties `((:created         :datetime ,(s-prefix "dct:created")) ;; timestamp of the answer
                (:text            :string   ,(s-prefix "schema:text"))) ;; content of the answer
                (:llm             :url      ,(s-prefix "dct:creator")) ;; LLM that was used (should this be a has-one relation to a resource representing the LLM? If so, we need a resource config for it)
  :has-one `((question            :via ,(s-prefix "schema:suggestedAnswer")
                                  :inverse t
                                  :as "question"))
  :has-many `((answer-source      :via ,(s-prefix "schema:hasPart") ;; the set of decisions that were used
                                  :as "sources")
              (annotation         :via ,(s-prefix "oa:hasTarget") ;; annotations for the answer as a whole
                                  :inverse t
                                  :as "annotations"))
  :resource-base (s-url "http://data.lblod.info/id/answers/")
  :on-path "answers")

(define-resource answer-source (annotation-target)
  :class (s-prefix "schema:Answer")
  :properties `((:confidence      :number ,(s-prefix "ext:confidence"))) ;; relevance score according to mu-search (NIF is not really suitable, since this is not an oa:Annotation)
  :has-one `((expression          :via ,(s-prefix "oa:hasSource") ;; decision (eli:Expression)
                                  :as "source")
             (answer              :via ,(s-prefix "schema:hasPart")
                                  :inverse t
                                  :as "answer"))
  :has-many `((annotation         :via ,(s-prefix "oa:hasTarget") ;; annotations for this answer & answer-source combination specifically
                                  :inverse t
                                  :as "annotations"))
  :resource-base (s-url "http://data.lblod.info/id/answer-sources/")
  :on-path "answer-sources")
