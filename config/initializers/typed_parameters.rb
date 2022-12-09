# frozen_string_literal: true

require_dependency Rails.root.join "lib", "typed_parameters"

TypedParameters.configure do |config|
  config.path_transform = :lower_camel
end
