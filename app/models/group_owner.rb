class GroupOwner < ApplicationRecord
  belongs_to :account
  belongs_to :group
  belongs_to :owner,
    polymorphic: true

  validates :account,
    presence: true
  validates :group,
    scope: { by: :account_id },
    presence: true
  validates :owner,
    scope: { by: :account_id },
    presence: true
end
