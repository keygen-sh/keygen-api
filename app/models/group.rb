class Group < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account

  has_many :users
  has_many :licenses
  has_many :machines
  has_many :owners,
    class_name: 'GroupOwner',
    dependent: :delete_all

  validates :account,
    presence: true

  scope :for_user, -> u {
    joins(:users)
      .where(users: u)
      .union(
        joins(:owners).where(owners: { owner_type: User.name, owner_id: u })
      )
      .distinct
  }

  scope :for_license, -> l {
    joins(:licenses).where(licenses: l)
  }

  scope :for_machine, -> m {
    joins(:machines).where(machines: m)
  }
end
