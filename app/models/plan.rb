class Plan < ApplicationRecord
  include Paginatable

  has_many :accounts
end
