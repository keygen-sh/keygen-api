# frozen_string_literal: true

Mime::Type.register 'application/octet-stream', :binary
Mime::Type.register 'application/vnd.api+json', :jsonapi, %W[
  application/vnd.keygen+json
]
