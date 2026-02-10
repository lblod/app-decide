defmodule Dispatcher do
  use Matcher

  define_accept_types [
    json: ["application/json", "application/vnd.api+json"],
    html: ["text/html", "application/xhtml+html"],
    sparql: ["application/sparql-results+json"],
    any: ["*/*"]
  ]

  define_layers([:static, :sparql, :api_services, :frontend_fallback, :resources, :not_found])

  options "/*path", _ do
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

  #################
  # Jobs & tasks
  #################

  match "/jobs/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/jobs/"
  end

  match "/annotation-jobs/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/annotation-jobs/"
  end

  match "/tasks/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/tasks/"
  end

  match "/scheduled-jobs/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/scheduled-jobs/"
  end

  match "/scheduled-tasks/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/scheduled-tasks/"
  end

  match "/cron-schedules/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/cron-schedules/"
  end

  #################
  # Frontend Harvesting
  #################

  match "/data-containers/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/data-containers/"
  end

  match "/job-errors/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/job-errors/"
  end

  match "/reports/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/reports/"
  end

  match "/log-entries/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/log-entries/"
  end

  match "/log-levels/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/log-levels/"
  end

  match "/status-codes/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/status-codes/"
  end

  match "/log-sources/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/log-sources/"
  end

  match "/remote-data-objects/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/remote-data-objects/"
  end

  match "/harvesting-collections/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/harvesting-collections/"
  end

  match "/node-shapes/*path", %{accept: [:json], layer: :api_services} do
    Proxy.forward conn, path, "http://resource/node-shapes/"
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
    Proxy.forward conn, path, "http://resource/datasets/"
  end

  match "/catalogs/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/catalogs/"
  end

  match "/distributions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/distributions/"
  end

  match "/catalog-records/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/catalog-records/"
  end

  match "/concepts/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/concepts/"
  end

  match "/concept-schemes/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/concept-schemes/"
  end

  match "/agents/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/agents/"
  end

  match "/formats/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/formats/"
  end

  match "/pages/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/pages/"
  end

  match "/activities/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/activities/"
  end

  match "/legislative-processes/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/legislative-processes/"
  end

  match "/legislative-process-works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/legislative-process-works/"
  end

  match "/draft-legislation-works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/draft-legislation-works/"
  end

  match "/parliamentary-terms/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/parliamentary-terms/"
  end

  match "/participations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/participations/"
  end

  match "/foreseen-activities/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/foreseen-activities/"
  end

  match "/decisions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/decisions/"
  end

  match "/votes/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/votes/"
  end

  match "/process-stages/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/process-stages/"
  end

  match "/organizations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/organizations/"
  end

  match "/people/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/people/"
  end

  match "/legal-expressions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/legal-expressions/"
  end

  match "/works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/works/"
  end

  match "/expressions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/expressions/"
  end

  match "/manifestations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/manifestations/"
  end

  match "/complex-works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/complex-works/"
  end

  match "/annotations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/annotations/"
  end

  match "/specific-resources/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/specific-resources/"
  end

  match "/locations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/locations/"
  end

  match "/geometries/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/geometries/"
  end

  #################################################################
  # FILES
  #################################################################

  get "/files/:id/download", %{accept: [:any]} do
    Proxy.forward(conn, [], "http://file/files/" <> id <> "/download")
  end

  get "/files/*path", %{layer: :api_services, accept: %{json: true}} do
    Proxy.forward(conn, path, "http://resource/files/")
  end

  #################
  # LOGIN
  #################

  match "/gebruikers/*path", %{layer: :resources, accept: %{any: true}} do
    forward(conn, path, "http://resource/gebruikers/")
  end

  match "/accounts/*path", %{layer: :resources, accept: %{any: true}} do
    forward(conn, path, "http://resource/accounts/")
  end

  match "/bestuurseenheids/*path", %{layer: :resources, accept: %{any: true}} do
    forward(conn, path, "http://resource/bestuurseenheids/")
  end

  match "/sessions/*path", %{reverse_host: ["dashboard" | _rest]} do
    Proxy.forward(conn, path, "http://login/sessions/")
  end

  match "/mock/sessions/*path", %{reverse_host: ["dashboard" | _rest]} do
    Proxy.forward(conn, path, "http://mocklogin/sessions/")
  end

  match "/sessions/*path", %{layer: :api_services, accept: %{any: true}} do
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

  match "/index.html", %{layer: :static} do
    forward(conn, [], "http://frontend/index.html")
  end

  get "/assets/*path", %{layer: :static} do
    forward(conn, path, "http://frontend/assets/")
  end

  get "/@appuniversum/*path", %{layer: :static} do
    forward(conn, path, "http://frontend/@appuniversum/")
  end


  #################
  # FRONTEND PAGES
  #################

  # self-service
  match "/*path", %{reverse_host: ["dashboard" | _rest], accept: %{html: true}} do
    # we don't forward the path, because the app should take care of this in the browser.
    forward(conn, [], "http://frontend-harvesting/index.html")
  end

  match "/*path", %{layer: :frontend_fallback, accept: %{html: true}} do
    # we don't forward the path, because the app should take care of this in the browser.
    forward(conn, [], "http://frontend/index.html")
  end

  #################
  # DCAT
  #################

  match "/dcat/*path" do
    forward(conn, path, "http://dcat/")
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
