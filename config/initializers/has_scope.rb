# frozen_string_literal: true

HasScope.tap do |config|
  config::ALLOWED_TYPES[:any] = [[String, Numeric, Array, Hash, ActionController::Parameters]]
end
