class GroupOwner < ApplicationRecord
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :group
  belongs_to :user

  has_account default: -> { group&.account_id }
  has_environment default: -> { group&.environment_id }

  validates :group,
    scope: { by: :account_id }
  validates :user,
    uniqueness: { message: 'already exists', scope: %i[group_id user_id] },
    scope: { by: :account_id }

  scope :accessible_by, -> accessor {
    case accessor
    in role: Role(:admin | :product)
      self.all
    in role: Role(:environment)
      self.for_environment(accessor.id)
    in role: Role(:user)
      self.where(group_id: accessor.group_id)
          .or(
            where(group_id: accessor.group_ids),
          )
    in role: Role(:license)
      self.where(group_id: accessor.group_id)
    else
      self.none
    end
  }
end
