defmodule Dispatcher do
  use Matcher

  define_accept_types [
    json: ["application/json", "application/vnd.api+json"],
    html: ["text/html", "application/xhtml+html"],
    sparql: ["application/sparql-results+json"],
    any: ["*/*"]
  ]

  define_layers([:static, :sparql, :api_services, :frontend, :resources, :not_found])

  options "/*_path", _ do
    conn
    |> Plug.Conn.put_resp_header("access-control-allow-headers", "content-type,accept")
    |> Plug.Conn.put_resp_header("access-control-allow-methods", "*")
    |> send_resp(200, "{ \"message\": \"ok\" }")
  end

  #################
  # API Services
  #################

  match "/sparql", %{ reverse_host: ["dashboard" | _rest], accept: [:any], layer: :sparql } do
    Proxy.forward conn, [], "http://database:8890/sparql"
  end

  match "/annotation-review/*path", %{ accept: [:any], layer: :static } do
    Proxy.forward conn, path, "http://annotation-review/"
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
  # RESOURCES
  #################

  match "/concepts/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/concepts/"
  end

  match "/concept-schemes/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/concept-schemes/"
  end

  match "/organizations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/organizations/"
  end

  match "/expressions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/expressions/"
  end

  match "/works/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/works/"
  end

  match "/legal-expressions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/legal-expressions/"
  end

  match "/manifestations/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://cache/manifestations/"
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

  match "/sessions/*path", %{reverse_host: ["dashboard" | _rest]} do
    Proxy.forward(conn, path, "http://login/sessions/")
  end

  match "/mock/sessions/*path", %{reverse_host: ["dashboard" | _rest]} do
    Proxy.forward(conn, path, "http://mocklogin/sessions/")
  end

  match "/sessions/*path", %{layer: :api_services, accept: %{any: true}} do
    Proxy.forward(conn, path, "http://login/sessions/")
  end

  match "/mock/sessions/*path", %{layer: :api_services, accept: %{any: true} } do
    Proxy.forward(conn, path, "http://mocklogin/sessions/")
  end

  ###############
  # STATIC
  ###############

  # dashboard (frontend-harvesting)
  match "/index.html", %{reverse_host: ["dashboard" | _rest], layer: :static} do
    forward(conn, [], "http://frontend-harvesting/index.html")
  end

  get "/assets/*path", %{reverse_host: ["dashboard" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-harvesting/assets/")
  end

  get "/@appuniversum/*path", %{reverse_host: ["dashboard" | _rest], layer: :static} do
    forward(conn, path, "http://frontend-harvesting/@appuniversum/")
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

  #################
  # FRONTEND PAGES
  #################

  match "/*_path", %{reverse_host: ["dashboard" | _rest], accept: %{html: true}, layer: :frontend } do
    forward(conn, [], "http://frontend-harvesting/index.html")
  end

  match "/*_path", %{reverse_host: ["human-validator" | _rest], accept: %{html: true}, layer: :frontend} do
    forward(conn, [], "http://frontend-human-validator/index.html")
  end

  #################
  # NOT FOUND
  #################

  match "/*_path", %{ layer: :not_found } do
    send_resp(conn, 404, "Route not found.  See config/dispatcher.ex")
  end
end
