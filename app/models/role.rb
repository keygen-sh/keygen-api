class Role < ApplicationRecord
  belongs_to :resource, polymorphic: true

  validates :resource, presence: { message: "must exist" }
  validates :name, role: true
end
