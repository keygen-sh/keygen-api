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

  # Give products the ability to read all groups
  scope :for_product, -> id { self }

  scope :for_user, -> u {
    joins(:owners).where(owners: { user_id: u })
  }
end
