class GroupOwner < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :group
  belongs_to :user

  validates :account,
    presence: { message: 'must exist' }
  validates :group,
    presence: { message: 'must exist' },
    scope: { by: :account_id }
  validates :user,
    uniqueness: { message: 'already exists', scope: %i[group_id user_id] },
    presence: { message: 'must exist' },
    scope: { by: :account_id }
end
