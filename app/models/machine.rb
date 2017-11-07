class Machine < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :license
  has_one :product, through: :license
  has_one :policy, through: :license
  has_one :user, through: :license

  validates :account, presence: { message: "must exist" }
  validates :license, presence: { message: "must exist" }

  validates :fingerprint, presence: true, blank: false, uniqueness: { scope: :license_id }

  scope :fingerprint, -> (fingerprint) { where fingerprint: fingerprint }
  scope :license, -> (id) { where license: id }
  scope :user, -> (id) { joins(:license).where licenses: { user_id: id } }
  scope :product, -> (id) { joins(license: [:policy]).where policies: { product_id: id } }
end

# == Schema Information
#
# Table name: machines
#
#  id          :uuid             not null, primary key
#  fingerprint :string
#  ip          :string
#  hostname    :string
#  platform    :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  name        :string
#  metadata    :jsonb
#  account_id  :uuid
#  license_id  :uuid
#
# Indexes
#
#  index_machines_on_created_at_and_account_id  (created_at,account_id)
#  index_machines_on_created_at_and_id          (created_at,id) UNIQUE
#  index_machines_on_created_at_and_license_id  (created_at,license_id)
#  index_machines_on_id                         (id) UNIQUE
#
