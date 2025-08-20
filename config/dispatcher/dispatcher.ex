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
  # ELI
  #################

  match "/legal-expressions/*path", %{ accept: [:json], layer: :resources } do
    Proxy.forward conn, path, "http://resource/legal-expressions"
  end

  #################
  # NOT FOUND
  #################

  match "/*_path", %{ layer: :not_found } do
    send_resp(conn, 404, "Route not found.  See config/dispatcher.ex")
  end
end
