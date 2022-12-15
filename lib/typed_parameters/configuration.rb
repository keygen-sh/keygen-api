# frozen_string_literal: true

module TypedParameters
  class Configuration
    include ActiveSupport::Configurable

    ##
    # ignore_nil_optionals defines how nil optionals are handled.
    # When enabled, optional params that are nil will be ignored if
    # the schema does not allow_nil.
    config_accessor(:ignore_nil_optionals) { false }

    ##
    # path_transform defines the casing for parameter paths.
    config_accessor(:path_transform) { nil }

    ##
    # key_transform defines the casing for parameter keys.
    config_accessor(:key_transform) { nil }
  end
end
