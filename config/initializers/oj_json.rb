require 'oj'

Oj::Rails.tap do |oj|
  oj.set_encoder
  oj.set_decoder
  oj.optimize
  oj.mimic_JSON
end