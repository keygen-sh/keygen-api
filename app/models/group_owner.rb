class GroupOwner < ApplicationRecord
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :group
  belongs_to :user

  has_environment default: -> { group&.environment_id }
  has_account default: -> { group&.account_id }

  validates :group,
    scope: { by: :account_id }
  validates :user,
    uniqueness: { message: 'already exists', scope: %i[group_id user_id] },
    scope: { by: :account_id }

  scope :accessible_by, -> accessor {
    case accessor
    in role: Role(:admin | :product)
      all
    in role: Role(:environment)
      for_environment(accessor.id)
    in role: Role(:user)
      where(group_id: accessor.group_id)
        .or(
          where(group_id: accessor.group_ids),
        )
    in role: Role(:license)
      where(group_id: accessor.group_id)
    else
      none
    end
  }
end
