# frozen_string_literal: true

module TypedParameters
  class Configuration
    include ActiveSupport::Configurable

    ##
    # path_transform defines the casing for parameter paths.
    config_accessor(:path_transform) { nil }

    ##
    # key_transform defines the casing for parameter keys.
    config_accessor(:key_transform) { nil }
  end
end
