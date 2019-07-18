# frozen_string_literal: true

class Role < ApplicationRecord
  belongs_to :resource, polymorphic: true

  validates :name, inclusion: { in: %w[user admin], message: "must be a valid user role" }, if: -> { resource.is_a? User }
  validates :name, inclusion: { in: %w[product], message: "must be a valid product role" }, if: -> { resource.is_a? Product }
end
