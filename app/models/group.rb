class Group < ApplicationRecord
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  has_many :group_permissions
  has_many :permissions,
    through: :group_permissions

  has_many :users,
    dependent: :nullify
  has_many :licenses,
    dependent: :nullify
  has_many :machines,
    dependent: :nullify
  has_many :owners,
    class_name: 'GroupOwner',
    dependent: :delete_all

  has_account
  has_environment

  # Give products the ability to read all groups
  scope :for_product, -> id { self }

  scope :for_user, -> u {
    joins(:users)
      .where(users: { id: u })
      .union(
        joins(:owners).where(owners: { user_id: u })
      )
      .distinct
  }

  scope :for_license, -> l {
    joins(:licenses).where(licenses: { id: l })
  }

  scope :for_machine, -> m {
    joins(:machines).where(machines: { id: m })
  }

  scope :search_name, -> term {
    return none if
      term.blank?

    where('groups.name ILIKE ?', "%#{sanitize_sql_like(term)}%")
  }
end
