module Limitable
  LIMIT_UPPER = 100
  LIMIT_LOWER = 1

  extend ActiveSupport::Concern

  included do
    # Since we can't redefine limit (stupid), we're defining a lim scope to add
    # additional validation on the allowed range for limit
    scope :lim, -> (num) {
      num = num.to_i

      if num < LIMIT_LOWER || num > LIMIT_UPPER
        raise InvalidLimitError, "limit must be a number between #{LIMIT_LOWER} and #{LIMIT_UPPER} (got #{num})"
      end

      limit num
    }
  end

  class InvalidLimitError < StandardError; end
end
