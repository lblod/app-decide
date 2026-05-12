(in-package :mu-cl-resources)

(define-resource annotation ()
  :class (s-prefix "oa:Annotation")
  :properties `((:confidence :number ,(s-prefix "nif:confidence"))
                (:motivated-by :url ,(s-prefix "oa:motivatedBy")))
  :has-one `((annotation-target :via ,(s-prefix "oa:hasTarget")
                                :as "has-target")
             (annotation-body :via ,(s-prefix "oa:hasBody")
                       :as "has-body"))
  :features '(include-uri)
  :resource-base (s-url "http://data.lblod.info/id/annotations/")
  :on-path "annotations")

(define-resource annotation-target () ;; generic resource class to serve as a target for annotations, to be extended with specific classes
  :class (s-prefix "ext:AnnotationTarget")
  :has-many `((annotation :via ,(s-prefix "oa:hasTarget")
              :as "annotations"
              :inverse t))
  :resource-base (s-url "http://data.lblod.info/id/annotation-targets/")
  :on-path "annotation-targets")

(define-resource annotation-body () ;; generic resource class to serve as a body for annotations, to be extended with specific classes
  :class (s-prefix "ext:AnnotationBody")
  :has-one `((annotation :via ,(s-prefix "oa:hasBody")
              :as "annotation"
              :inverse t))
  :resource-base (s-url "http://data.lblod.info/id/annotation-bodies/")
  :on-path "annotation-bodies")

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
                (:text            :string   ,(s-prefix "schema:text")) ;; content of the answer
                (:llm             :url      ,(s-prefix "dct:creator"))) ;; LLM that was used (should this be a has-one relation to a resource representing the LLM? If so, we need a resource config for it)
  :has-one `((question            :via ,(s-prefix "schema:suggestedAnswer")
                                  :inverse t
                                  :as "question"))
  :has-many `((quotation      :via ,(s-prefix "schema:citation") ;; the set of decisions that were used
                                  :as "sources"))
  ;; has-many annotations for the answer as a whole (inherited from annotation-target)
  :resource-base (s-url "http://data.lblod.info/id/answers/")
  :on-path "answers")

(define-resource quotation (annotation-target)
  :class (s-prefix "schema:Quotation")
  :properties `((:confidence      :number ,(s-prefix "ext:confidence"))) ;; relevance score according to mu-search (NIF is not really suitable, since this is not an oa:Annotation)
  :has-one `((expression          :via ,(s-prefix "oa:hasSource") ;; decision (eli:Expression)
                                  :as "source")
             (answer              :via ,(s-prefix "schema:citation")
                                  :inverse t
                                  :as "answer"))
  ;; has-many annotations for this answer & quotation combination specifically (inherited from annotation-target)
  :resource-base (s-url "http://data.lblod.info/id/quotations/")
  :on-path "quotations")
