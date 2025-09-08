defmodule Dispatcher do
  use Matcher

  define_accept_types [
    json: ["application/json", "application/vnd.api+json"],
    html: ["text/html", "application/xhtml+html"],
    sparql: ["application/sparql-results+json"],
    any: ["*/*"]
  ]

  define_layers [ :resources, :not_found ]

  #################
  # RESOURCES
  #################

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
  # NOT FOUND
  #################

  match "/*_path", %{ layer: :not_found } do
    send_resp(conn, 404, "Route not found.  See config/dispatcher.ex")
  end
end
