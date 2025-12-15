;; 
;; Authentication Configuration
;; 

(define-resource authentication-configuration ()
  :class (s-prefix "dgftSec:AuthenticationConfiguration")
  :has-one `((credential :via ,(s-prefix "dgftSec:secrets")
              :as "credential")
            (security-scheme :via ,(s-prefix "dgftSec:securityConfiguration")
              :as "security-scheme"))
  :resource-base (s-url "http://data.lblod.info/id/authentication-configurations/")
  :features `(include-uri)
  :on-path "authentication-configurations")

;; 
;; Secrets (Security Credentials)
;; 

(define-resource credential ()
  ;; Abstract superclass, so that it can be used in the frontend
  :class (s-prefix "dgftSec:Credentials")
  :resource-base (s-url "http://data.lblod.info/id/credentials/")
  :features '(include-uri)
  :on-path "credentials")

(define-resource basic-authentication-credential (credential)
  :class (s-prefix "dgftSec:BasicAuthenticationCredentials")
  :properties `((:username :string ,(s-prefix "meb:username"))
                (:password :string ,(s-prefix "muAccount:password")))
  :resource-base (s-url "http://data.lblod.info/id/basic-authentication-credentials/")
  :features '(include-uri)
  :on-path "basic-authentication-credentials")

(define-resource oauth2-credential (credential)
  :class (s-prefix "dgftSec:OAuth2Credentials")
  :properties `((:client-id      :string ,(s-prefix "dgftOauth:clientId"))
                (:client-secret  :string ,(s-prefix "dgftOauth:clientSecret")))
  :resource-base (s-url "http://data.lblod.info/id/oauth-2-credentials/")
  :features '(include-uri)
  :on-path "oauth2-credentials")

;;
;; Security Schemes
;;

(define-resource security-scheme ()
  ;; Abstract superclass
  :class (s-prefix "wotSec:SecurityScheme")
  :resource-base (s-url "http://data.lblod.info/id/security-schemes/")
  :features '(include-uri)
  :on-path "security-schemes")

(define-resource basic-security-scheme (security-scheme)
  :class (s-prefix "wotSec:BasicSecurityScheme")
  :resource-base (s-url "http://data.lblod.info/id/basic-security-schemes/")
  :features '(include-uri)
  :on-path "basic-security-schemes")

(define-resource oauth2-security-scheme (security-scheme)
  :class (s-prefix "wotSec:OAuth2SecurityScheme")
  :properties `((:token :string ,(s-prefix "wotSec:token"))
                (:flow  :string ,(s-prefix "wotSec:flow")))
  :resource-base (s-url "http://data.lblod.info/id/oauth2-security-schemes/")
  :features '(include-uri)
  :on-path "oauth2-security-schemes")