;;;;;;;;;;;;;;;;;;;
;;; delta messenger
(in-package :delta-messenger)

(setf *delta-handlers* nil)
(add-delta-logger)
(add-delta-messenger "http://deltanotifier/")


; CONFIGURATION

(in-package :client)
(setf *log-sparql-query-roundtrip* t)
(setf *backend* "http://virtuoso:8890/sparql")

(in-package :support)
(setf *string-max-size* nil)

(in-package :server)
(setf *log-incoming-requests-p* t)

; ACCESS RIGHTS
;; The following functionality allows to easily switch between the manually written policy and one
;; generated from an ODRL policy. When updating the app's policy, apply the necessary changes in the
;; `decide.lisp' file.
(defparameter *use-odrl-policy-p*
  (and (uiop:getenv "USE_ODRL_POLICY")
       (string-equal (uiop:getenv "USE_ODRL_POLICY") "true"))
  "Indicate whether to use the configuration generated from ODRL or the rules in this file.")

(let ((config-path
        (if *use-odrl-policy-p*
            "./odrl/decideAuthorizationPolicy.lisp"
            "./config/decide.lisp")))
  (format t "~& >> Loading policy from file: ~A" config-path)
  (load config-path))
