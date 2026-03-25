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
