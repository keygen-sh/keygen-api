module Paginatable
  extend ActiveSupport::Concern

  included do
    scope :page, -> (number, size) { paginate(number).per size }
  end
end
