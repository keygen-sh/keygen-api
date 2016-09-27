class Role < ApplicationRecord
  has_and_belongs_to_many :tokens, join_table: :tokens_roles
  belongs_to :resource,
             polymorphic: true,
             optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  scopify
end
