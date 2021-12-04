# frozen_string_literal: true

require 'oj'

Oj::Rails.tap do |oj|
  oj.set_encoder
  oj.set_decoder
  oj.optimize
  oj.mimic_JSON
end

# After setting Oj as the default JSON serializer, disable
# Rails' default behavior for escaping HTML entities in
# JSON, i.e. & => \u0026.
ActiveSupport::JSON::Encoding.escape_html_entities_in_json = false
