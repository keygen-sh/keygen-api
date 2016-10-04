module Paginatable
  extend ActiveSupport::Concern

  included do
    scope :page, -> (page = {}) { paginate(page[:number]).per page[:size] }
  end
end
