class Machine < ApplicationRecord
  include Paginatable

  belongs_to :account
  belongs_to :license
  has_one :product, through: :license
  has_one :user, through: :license

  serialize :meta, Hash

  validates :account, presence: { message: "must exist" }
  validates :license, presence: { message: "must exist" }

  validates :fingerprint, presence: true, blank: false, uniqueness: { scope: :license_id }
  validates :name, presence: true, allow_nil: true, uniqueness: { scope: :license_id }

  scope :license, -> (id) { where license: License.decode_id(id) }
  scope :user, -> (id) { joins(:license).where licenses: { user_id: User.decode_id(id) } }
  scope :product, -> (id) { joins(license: [:policy]).where policies: { product_id: Product.decode_id(id) } }
end

# == Schema Information
#
# Table name: machines
#
#  id          :integer          not null, primary key
#  fingerprint :string
#  ip          :string
#  hostname    :string
#  platform    :string
#  account_id  :integer
#  license_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  name        :string
#  meta        :string
#
# Indexes
#
#  index_machines_on_account_id  (account_id)
#  index_machines_on_license_id  (license_id)
#
