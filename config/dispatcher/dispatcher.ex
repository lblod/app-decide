defmodule Dispatcher do
  use Matcher

  define_accept_types [
    json: ["application/json", "application/vnd.api+json"],
    html: ["text/html", "application/xhtml+html"],
    sparql: ["application/sparql-results+json"],
    any: ["*/*"]
  ]

  define_layers([:static, :sparql, :frontend, :api_services, :resources, :frontend_fallback, :not_found])

  options "/*_path", _ do
    conn
    |> Plug.Conn.put_resp_header("access-control-allow-headers", "content-type,accept")
    |> Plug.Conn.put_resp_header("access-control-allow-methods", "*")
    |> send_resp(200, "{ \"message\": \"ok\" }")
  end

  #################
  # API Services
  #################
  # by setting an ISSUER_URL with a path component, we can in theory host multiple issuers on the same domain.
  # it does require fiddling a bit with the 'well known paths' though.

  match "/vc-verifier/sessions/*path", %{ layer: :static, accept: [:any]} do
    Proxy.forward conn, path, "http://vc-issuer/sessions/"
  end

  match "/vc-verifier/*path", %{ accept: [:any], layer: :static } do
    Proxy.forward conn, path, "http://vc-issuer/verifier/"
  end

  match "/vc-issuer/.well-known/openid-credential-issuer", %{ accept: [:json], layer: :static } do
    Proxy.forward conn, [], "http://vc-issuer/issuer/issuer_metadata"
  end

  match "/.well-known/openid-credential-issuer/vc-issuer", %{ accept: [:json], layer: :static } do
    Proxy.forward conn, [], "http://vc-issuer/issuer/issuer_metadata"
  end

  match "/vc-issuer/.well-known/oauth-authorization-server", %{ accept: [:json], layer: :static } do
    Proxy.forward conn, [], "http://vc-issuer/issuer/authorization_metadata"
  end

  match "/.well-known/oauth-authorization-server/vc-issuer", %{ accept: [:json], layer: :static } do
    Proxy.forward conn, [], "http://vc-issuer/issuer/authorization_metadata"
  end

  match "/vc-issuer/.well-known/vct", %{ accept: [:json], layer: :static } do
    Proxy.forward conn, [], "http://vc-issuer/issuer/vct"
  end

  match "/.well-known/vct/vc-issuer", %{ accept: [:json], layer: :static } do
    Proxy.forward conn, [], "http://vc-issuer/issuer/vct"
  end


  # layer order matters! we need to intercept the .well-known variants first, hence :static
  match "/vc-issuer/*path", %{ accept: [:any], layer: :api_services } do
    Proxy.forward conn, path, "http://vc-issuer/issuer/"
  end

  get "/question-answering/openapi.json", %{ accept: [:any], layer: :api_services } do
    Proxy.forward conn, [], "http://question-answering/openapi.json"
  end

  match "/question-answering/*path", %{ accept: [:any], layer: :api_services } do
    Proxy.forward conn, path, "http://question-answering/question-answering/"
  end

  match "/api/sparql", %{ accept: [:any], layer: :sparql } do
    Proxy.forward conn, [], "http://database:8890/sparql"
  end

  match "/api/private/sparql", %{ accept: [:any], layer: :sparql } do
    Proxy.forward conn, [], "http://dsp-auth-wrapper/sparql"
  end

  match "/annotation-review/*path", %{ accept: [:any], layer: :static } do
    Proxy.forward conn, path, "http://annotation-review/"
  end

  match "/policy-impact-report/*path", %{ accept: [:any], layer: :static } do
    Proxy.forward conn, path, "http://policy-impact-report/"
  end

  match "/shacl-reports/*path", %{ accept: [:any], layer: :static } do
    Proxy.forward conn, path, "http://report-generation/"
  end

  #################
  # Jobs & tasks
  #################

  match "/jobs/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/jobs/"
  end

  match "/annotation-jobs/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/annotation-jobs/"
  end

  match "/tasks/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/tasks/"
  end

  match "/scheduled-jobs/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/scheduled-jobs/"
  end

  match "/scheduled-annotation-jobs/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/scheduled-annotation-jobs/"
  end

  match "/scheduled-tasks/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/scheduled-tasks/"
  end

  match "/cron-schedules/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/cron-schedules/"
  end

  #################
  # Frontend Harvesting
  #################

  match "/data-containers/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/data-containers/"
  end

  match "/job-errors/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/job-errors/"
  end

  match "/reports/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/reports/"
  end

  match "/log-entries/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/log-entries/"
  end

  match "/log-levels/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/log-levels/"
  end

  match "/status-codes/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/status-codes/"
  end

  match "/log-sources/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/log-sources/"
  end

  match "/remote-data-objects/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/remote-data-objects/"
  end

  match "/harvesting-collections/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/harvesting-collections/"
  end

  match "/node-shapes/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://cache/node-shapes/"
  end

  #################
  # OPARL PROXY
  #################

  match "/oparl/*path", %{ accept: [:any], layer: :api_services } do
    Proxy.forward conn, path, "http://oparl-to-eli/oparl/"
  end

  match "/eli/*path", %{ accept: [:any], layer: :api_services } do
    Proxy.forward conn, path, "http://oparl-to-eli/eli/"
  end

  #################
  # RESOURCES
  #################

  match "/datasets/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/datasets/"
  end

  match "/catalogs/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/catalogs/"
  end

  match "/distributions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/distributions/"
  end

  match "/catalog-records/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/catalog-records/"
  end

  match "/concepts/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/concepts/"
  end

  match "/concept-schemes/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/concept-schemes/"
  end

  match "/agents/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/agents/"
  end

  match "/formats/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/formats/"
  end

  match "/pages/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/pages/"
  end

  match "/activities/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/activities/"
  end

  match "/legislative-processes/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/legislative-processes/"
  end

  match "/legislative-process-works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/legislative-process-works/"
  end

  match "/draft-legislation-works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/draft-legislation-works/"
  end

  match "/parliamentary-terms/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/parliamentary-terms/"
  end

  match "/participations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/participations/"
  end

  match "/foreseen-activities/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/foreseen-activities/"
  end

  match "/decisions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/decisions/"
  end

  match "/votes/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/votes/"
  end

  match "/process-stages/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/process-stages/"
  end

  match "/organizations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/organizations/"
  end

  match "/people/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/people/"
  end

  match "/legal-expressions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/legal-expressions/"
  end

  match "/works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/works/"
  end

  # NOTE (12/06/2026): This rule ensures requests for the `/expressions` route that
  # have `text/html` as accept-header are forwarded to the hvt frontend instead of
  # to resources.  Otherwise, requests meant for the frontend are matched by the
  # rule below and incorrectly forwarded to resources.  The prioritisation is
  # done by the layers.
  match "/expressions/*_path",  %{reverse_host: ["human-validator" | _rest], accept: [:html], layer: :frontend} do
    forward(conn, [], "http://frontend-human-validator/index.html")
  end

  match "/expressions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/expressions/"
  end

  match "/manifestations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/manifestations/"
  end

  match "/complex-works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/complex-works/"
  end

  match "/annotations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/annotations/"
  end

  match "/specific-resources/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/specific-resources/"
  end

  match "/text-position-selectors/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/text-position-selectors/"
  end

  match "/locations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/locations/"
  end

  match "/geometries/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/geometries/"
  end

  #################################################################
  # FILES
  #################################################################

  get "/files/:id/download", %{accept: [:any]} do
    Proxy.forward(conn, [], "http://file/files/" <> id <> "/download")
  end

  get "/files/*path", %{layer: :api_services, accept: %{json: true}} do
    Proxy.forward(conn, path, "http://cache/files/")
  end

  #################
  # LOGIN
  #################

  match "/gebruikers/*path", %{layer: :resources, accept: %{any: true}} do
    forward(conn, path, "http://cache/gebruikers/")
  end

  match "/accounts/*path", %{layer: :resources, accept: %{any: true}} do
    forward(conn, path, "http://cache/accounts/")
  end

  match "/bestuurseenheids/*path", %{layer: :resources, accept: %{any: true}} do
    forward(conn, path, "http://cache/bestuurseenheids/")
  end

  match "/sessions/*path", %{layer: :api_services, accept: %{any: true}} do
    Proxy.forward(conn, path, "http://login/sessions/")
  end

  match "/mock/sessions/*path", %{reverse_host: ["dashboard" | _rest]} do
    Proxy.forward(conn, path, "http://mocklogin/sessions/")
  end

  match "/sessions/*path", %{reverse_host: ["yasgui" | _rest]} do
    Proxy.forward(conn, path, "http://login/sessions/")
  end

  match "/mock/sessions/*path", %{reverse_host: ["yasgui" | _rest]} do
    Proxy.forward(conn, path, "http://mocklogin/sessions/")
  end

  match "/sessions/*path", %{reverse_host: ["ds" | _rest], layer: :api_services, accept: %{any: true}} do
    Proxy.forward(conn, path, "http://acmidm-login/sessions/")
  end

  match "/mock/sessions/*path", %{layer: :api_services, accept: %{any: true} } do
    Proxy.forward(conn, path, "http://mocklogin/sessions/")
  end

  ###############
  # STATIC
  ###############

  # self-service
  match "/index.html", %{reverse_host: ["dashboard" | _rest], layer: :static} do
    forward(conn, [], "http://frontend-harvesting/index.html")
  end

  get "/assets/*path", %{reverse_host: ["dashboard" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-harvesting/assets/")
  end

  get "/@appuniversum/*path", %{reverse_host: ["dashboard" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-harvesting/@appuniversum/")
  end

  # dcat
  match "/index.html",  %{reverse_host: ["ds" | _rest], layer: :static} do
    forward(conn, [], "http://frontend-dcat/index.html")
  end

  get "/assets/*path", %{reverse_host: ["ds" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-dcat/assets/")
  end

  get "/@appuniversum/*path",  %{reverse_host: ["ds" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-dcat/@appuniversum/")
  end

  # human validator
  match "/index.html",  %{reverse_host: ["human-validator" | _rest], layer: :static} do
    forward(conn, [], "http://frontend-human-validator/index.html")
  end

  get "/assets/*path", %{reverse_host: ["human-validator" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-human-validator/assets/")
  end

  get "/@appuniversum/*path",  %{reverse_host: ["human-validator" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-human-validator/@appuniversum/")
  end

  # yasgui
  match "/index.html",  %{reverse_host: ["yasgui" | _rest], layer: :static} do
    forward(conn, [], "http://frontend-yasgui/index.html")
  end

  get "/assets/*path", %{reverse_host: ["yasgui" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-yasgui/assets/")
  end

  get "/@appuniversum/*path",  %{reverse_host: ["yasgui" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-yasgui/@appuniversum/")
  end

  # smart search
  match "/index.html",  %{reverse_host: ["smart-search" | _rest], layer: :static} do
    forward(conn, [], "http://frontend-smart-search/index.html")
  end

  get "/assets/*path", %{reverse_host: ["smart-search" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-smart-search/assets/")
  end

  get "/@appuniversum/*path",  %{reverse_host: ["smart-search" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-smart-search/@appuniversum/")
  end


    # policy impact report
  match "/index.html",  %{reverse_host: ["policy-impact-report" | _rest], layer: :static} do
    forward(conn, [], "http://frontend-policy-impact-report/index.html")
  end

  get "/assets/*path", %{reverse_host: ["policy-impact-report" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-policy-impact-report/assets/")
  end

  get "/@appuniversum/*path",  %{reverse_host: ["policy-impact-report" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-policy-impact-report/@appuniversum/")
  end

  #################
  # FRONTEND PAGES
  #################

  # we don't forward the path, because the app should take care of this in the browser.

  # self-service
  match "/*_path", %{reverse_host: ["dashboard" | _rest], accept: %{html: true}, layer: :frontend_fallback } do
    forward(conn, [], "http://frontend-harvesting/index.html")
  end

  match "/*_path", %{ reverse_host: ["ds" | _rest], accept: %{html: true}, layer: :frontend_fallback } do
    forward(conn, [], "http://frontend-dcat/index.html")
  end

  match "/*_path", %{reverse_host: ["human-validator" | _rest], accept: %{html: true}, layer: :frontend_fallback} do
    forward(conn, [], "http://frontend-human-validator/index.html")
  end

  match "/*_path", %{reverse_host: ["yasgui" | _rest], accept: %{html: true}, layer: :frontend_fallback } do
    forward(conn, [], "http://frontend-yasgui/index.html")
  end

  match "/*_path", %{reverse_host: ["smart-search" | _rest], accept: %{html: true}, layer: :frontend_fallback} do
    forward(conn, [], "http://frontend-smart-search/index.html")
  end

  match "/*_path", %{reverse_host: ["policy-impact-report" | _rest], accept: %{html: true}, layer: :frontend_fallback} do
    forward(conn, [], "http://frontend-policy-impact-report/index.html")
  end

  #################
  # DCAT
  #################
  # NOTE (12/06/2026): This rule ensures requests for the `/dcat` route that
  # have `text/html` as accept-header are forwarded to the frontend instead of
  # the service.  Otherwise, requests meant for the frontend are matched by the
  # rule below and incorrectly forwarded to the service.  The prioritisation is
  # done by the layers.
  match "/dcat/*_path", %{ reverse_host: ["ds" | _rest], accept: %{html: true}, layer: :frontend } do
    forward(conn, [], "http://frontend-dcat/index.html")
  end

  get "/dcat/*path", %{ accept: [:any], layer: :api_services } do
    forward(conn, path, "http://dcat/")
  end

  ###############################################################
  # LDES
  ###############################################################
  match "/ldes/*path", %{ accept: %{any: true}, layer: :api_services} do
    Proxy.forward conn, path, "http://ldes-serve-feed/"
  end

  ##################
  # SEARCH
  ##################
  get "/search/*path", %{layer: :api_services, accept: [:json]} do
    Proxy.forward conn, path, "http://search/"
  end

  post "/search/:type/large-search", %{layer: :api_services, accept: [:json]} do
    Proxy.forward conn, [(type <> "/large-search")], "http://search/"
  end

  match "/embedding/*path", %{layer: :api_services, accept: [:json]} do
    Proxy.forward conn, path, "http://embedding/"
  end

  #################
  # NOT FOUND
  #################

  match "/*_path", %{ layer: :not_found } do
    send_resp(conn, 404, "Route not found.  See config/dispatcher.ex")
  end
end
