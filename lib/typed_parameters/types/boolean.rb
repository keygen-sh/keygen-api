# frozen_string_literal: true

module TypedParameters
  module Types
    COERCIBLE_TYPES = [String, Numeric].freeze
    TRUTHY_VALUES   = [
      1,
      '1',
      'true',
      'TRUE',
      't',
      'T',
    ].freeze

    register(
      type: :boolean,
      coerce: -> v {
        raise unless COERCIBLE_TYPES.any? { v.is_a?(_1) }

        v.in?(TRUTHY_VALUES)
      },
      match: -> v {
        v.is_a?(TrueClass) || v.is_a?(FalseClass)
      },
    )
  end
end
