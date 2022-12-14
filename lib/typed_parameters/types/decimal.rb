# frozen_string_literal: true

module TypedParameters
  module Types
    register(:decimal,
      coerce: -> v { v.blank? ? nil : v.to_d },
      match: -> v { v.is_a?(BigDecimal) },
    )
  end
end
