# frozen_string_literal: true

module TypedParameters
  module Types
    register(
      name: :object,
      type: :hash,
      accepts_block: true,
      scalar: false,
      match: -> v { v.is_a?(Hash) || v.is_a?(HashWithIndifferentAccess) },
    )
  end
end
