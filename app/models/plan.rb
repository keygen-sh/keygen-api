class Plan < ApplicationRecord
  has_many :accounts

  scope :page, -> (page = {}) {
    paginate(page[:number]).per page[:size]
  }
end
