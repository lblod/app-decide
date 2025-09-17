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

  ###############
  # STATIC
  ###############

  # self-service
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
  match "/*path", %{layer: :frontend_fallback, accept: %{html: true}} do
    # we don't forward the path, because the app should take care of this in the browser.
    forward(conn, [], "http://frontend/index.html")
  end

  #################
  # API Services
  #################
  match "/vc-issuer/*path", %{ accept: [:json], layer: :api_services } do
    Proxy.forward conn, path, "http://vc-issuer/"
  end

  match "/.well-known/openid-credential-issuer", %{ accept: [:json], layer: :api_services } do
    Proxy.forward conn, [], "http://vc-issuer/issuer_metadata"
  end

  match "/.well-known/oauth-authorization-server", %{ accept: [:json], layer: :api_services } do
    Proxy.forward conn, [], "http://vc-issuer/authorization_metadata"
  end

  match "/.well-known/vct", %{ accept: [:json], layer: :api_services } do
    Proxy.forward conn, [], "http://vc-issuer/vct"
  end


  #################
  # RESOURCES
  #################

  match "/datasets/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/datasets"
  end

  match "/catalogs/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/catalogs"
  end

  match "/distributions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/distributions"
  end

  match "/catalog-records/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/catalog-records"
  end

  match "/concepts/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/concepts"
  end

  match "/concept-schemes/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/concept-schemes"
  end

  match "/agents/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/agents"
  end

  match "/formats/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/formats"
  end

  match "/pages/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/pages"
  end

  match "/activities/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/activities"
  end

  match "/legislative-processes/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/legislative-processes"
  end

  match "/legislative-process-works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/legislative-process-works"
  end

  match "/draft-legislation-works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/draft-legislation-works"
  end

  match "/parliamentary-terms/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/parliamentary-terms"
  end

  match "/participations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/participations"
  end

  match "/foreseen-activities/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/foreseen-activities"
  end

  match "/decisions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/decisions"
  end

  match "/votes/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/votes"
  end

  match "/process-stages/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/process-stages"
  end

  match "/organizations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/organizations"
  end

  match "/people/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/people"
  end

  match "/legal-expressions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/legal-expressions"
  end

  match "/manifestations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/manifestations"
  end

  match "/complex-works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/complex-works"
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

  match "/sessions/*path", %{layer: :api_services, accept: %{any: true}} do
    Proxy.forward(conn, path, "http://mocklogin/sessions/")
  end

  match "/mock/sessions/*path" do
    forward(conn, path, "http://mocklogin/sessions/")
  end

  #################
  # NOT FOUND
  #################

  match "/*_path", %{ layer: :not_found } do
    send_resp(conn, 404, "Route not found.  See config/dispatcher.ex")
  end
end
