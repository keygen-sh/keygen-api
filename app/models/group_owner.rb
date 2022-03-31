class GroupOwner < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :group
  belongs_to :user

  validates :group,
    scope: { by: :account_id }
  validates :user,
    uniqueness: { message: 'already exists', scope: %i[group_id user_id] },
    scope: { by: :account_id }

  # Give products the ability to read all group owners
  scope :for_product, -> id { self }
end
