;;;;;;;;;;;;;;;;;;;
;;; delta messenger
(in-package :delta-messenger)

(setf *delta-handlers* nil)
(add-delta-logger)
(add-delta-messenger "http://deltanotifier/")


;; CONFIGURATION

(in-package :client)
(setf *log-sparql-query-roundtrip* t)
(setf *backend* "http://virtuoso:8890/sparql")

(in-package :support)
(setf *string-max-size* nil)

(in-package :server)
(setf *log-incoming-requests-p* t)

(in-package :odrl-config)
(setf *use-odrl-config-p* t)

;; ACCESS RIGHTS
;; The access policy is defined using ODRL in `./config.ttl'.
;; If you do want to use the Lisp configuration, uncomment the following 3 lines:
;; (setf *use-odrl-config-p* nil) ; Disables loading the ODRL config
;; (unless *use-odrl-config-p* ; Extra check to be sure only correct file is loaded
;;   (load "./config/decide.lisp")) ; Load the policy in the lisp file
