(in-package :mu-cl-resources)

(defparameter *default-page-size* 20)
(defparameter *include-count-in-paginated-responses* t)
(defparameter sparql:*experimental-no-application-graph-for-sudo-select-queries* t)
(defparameter *fetch-all-types-in-construct-queries* t)
(defparameter *supply-cache-headers-p* t)
(defparameter *cache-count-queries* nil)
(defparameter *cache-model-properties* t)
(defparameter *max-group-sorted-properties* nil)

(read-domain-file "eli.lisp")