module Paginatable
  SIZE_UPPER = 100
  SIZE_LOWER = 1
  PAGE_LOWER = 1

  extend ActiveSupport::Concern

  included do
    scope :page, -> (number, size) {
      number = number.to_i
      size = size.to_i

      if number < PAGE_LOWER
        raise InvalidPageError, "page number must be a number greater than 0 (got #{number})"
      end
      if size < SIZE_LOWER || size > SIZE_UPPER
        raise InvalidPageError, "page size must be a number between 1 and 100 (got #{size})"
      end

      paginate(number).per size
    }
  end

  class InvalidPageError < StandardError; end
end
