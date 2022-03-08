# frozen_string_literal: true

module Limitable
  LIMIT_UPPER = 100
  LIMIT_LOWER = 1

  extend ActiveSupport::Concern

  included do
    scope :with_limit, -> num {
      num = num.to_i

      if num < LIMIT_LOWER || num > LIMIT_UPPER
        raise Keygen::Error::InvalidScopeError.new(parameter: "limit"), "limit must be a number between #{LIMIT_LOWER} and #{LIMIT_UPPER} (got #{num})"
      end

      limit(num)
    }
  end
end
