class Machine < ApplicationRecord
  include Paginatable

  belongs_to :account
  belongs_to :license
  has_one :product, through: :license
  has_one :user, through: :license

  validates :account, presence: { message: "must exist" }
  validates :license, presence: { message: "must exist" }

  validates :fingerprint, presence: true, blank: false, uniqueness: { scope: :license_id }
  validates :name, presence: true, allow_nil: true, uniqueness: { scope: :license_id }

  scope :license, -> (id) { where license: License.decode_id(id) }
  scope :user, -> (id) { joins(:license).where licenses: { user_id: User.decode_id(id) } }
  scope :product, -> (id) { joins(license: [:policy]).where policies: { product_id: Product.decode_id(id) } }
end
