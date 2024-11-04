# frozen_string_literal: true

Mime::Type.register 'application/vnd.npm.install-v1+json', :npm
Mime::Type.register 'application/octet-stream', :binary
Mime::Type.register 'application/vnd.api+json', :jsonapi, %W[
  application/vnd.keygen+json
]

# adds pattern matching
class Mime::Type
  def deconstruct_keys(*) = { string:, symbol:, synonyms: }
  def deconstruct         = [symbol]
end
