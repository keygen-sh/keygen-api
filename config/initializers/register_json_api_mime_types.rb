Mime::Type.unregister :json
Mime::Type.register "application/vnd.api+json", :json, %W[
  application/vnd.api+json
  application/json
  text/x-json
]
