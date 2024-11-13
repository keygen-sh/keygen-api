# frozen_string_literal: true

Mime::Type.register 'application/octet-stream', :binary
Mime::Type.register 'application/vnd.api+json', :jsonapi, %W[
  application/vnd.keygen+json
]

Mime::Type.register 'application/vnd.oci+json', :oci, %W[
  application/vnd.oci.image.manifest.v1+json
  application/vnd.oci.image.index.v1+json
]

# adds pattern matching
class Mime::Type
  def deconstruct_keys(*) = { string:, symbol:, synonyms: }
  def deconstruct         = [symbol]
end
