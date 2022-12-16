# frozen_string_literal: true

module TypedParameters
  module Types
    module Boolean
      COERCIBLE_TYPES = [String, Numeric].freeze
      TRUTHY_VALUES   = [
        1,
        '1',
        'true',
        'TRUE',
        't',
        'T',
        'yes',
        'YES',
        'y',
        'Y',
      ].freeze
    end

    register(:boolean,
      coerce: -> v {
        return nil unless
          Boolean::COERCIBLE_TYPES.any? { v.is_a?(_1) }

        v.in?(Boolean::TRUTHY_VALUES)
      },
      match: -> v {
        v.is_a?(TrueClass) || v.is_a?(FalseClass)
      },
    )
  end
end
