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

  scope :accessible_by, -> accessor {
    case accessor
    in role: { name: 'admin' | 'product' }
      self.all
    in role: { name: 'user' }
      self.where(group_id: accessor.group_id)
          .or(
            where(group_id: accessor.group_ids),
          )
    in role: { name: 'license' }
      self.where(group_id: accessor.group_id)
    else
      self.none
    end
  }
end
