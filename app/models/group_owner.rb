class GroupOwner < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :group
  belongs_to :owner,
    class_name: 'User'

  validates :account,
    presence: { message: 'must exist' }
  validates :group,
    presence: { message: 'must exist' },
    scope: { by: :account_id }
  validates :owner,
    uniqueness: { message: 'already exists', scope: %i[group_id owner_type owner_id] },
    presence: { message: 'must exist' },
    scope: { by: :account_id }
end
