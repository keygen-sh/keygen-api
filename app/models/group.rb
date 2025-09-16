class Group < ApplicationRecord
  include Keygen::PortableClass
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

  has_environment
  has_account

  validates :name,
    length: { minimum: 1, maximum: 255 }

  validates :metadata,
    json: {
      maximum_bytesize: 16.kilobytes,
      maximum_depth: 4,
      maximum_keys: 64,
    }

  # Give products the ability to read all groups
  scope :for_product, -> id { self }

  scope :for_user, -> u {
    joins(:users)
      .where(users: { id: u })
      .distinct
      .union(
        joins(:owners).where(owners: { user_id: u })
      )
      .reorder(
        "#{table_name}.created_at": DEFAULT_SORT_ORDER,
      )
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
