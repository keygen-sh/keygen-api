# frozen_string_literal: true

module TypedParameters
  module Types
    register(:hash,
      name: :object,
      accepts_block: true,
      scalar: false,
      coerce: -> v { v.respond_to?(:to_h) ? v.to_h : {} },
      match: -> v { v.is_a?(Hash) },
    )
  end
end
