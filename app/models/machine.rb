class Machine < ApplicationRecord
  include Limitable
  include Pageable
  include Searchable

  belongs_to :account
  belongs_to :license
  has_one :product, through: :license
  has_one :policy, through: :license
  has_one :user, through: :license

  search(
    attributes: [:id, :fingerprint, :metadata],
    relationships: {
      product: [:id, :name],
      policy: [:id, :name],
      license: [:id, :key],
      user: [:id, :email]
    }
  )

  validates :account, presence: { message: "must exist" }
  validates :license, presence: { message: "must exist" }

  # Disallow machine overages when the policy is not set to concurrent
  validate on: :create do |machine|
    next if machine.policy.nil? ||
            machine.policy.concurrent ||
            machine.license.nil? ||
            machine.license.machines.empty?

    next unless machine.license.machines.count >= machine.policy.max_machines rescue false

    machine.errors.add :base, "machine count has reached maximum allowed by current policy (#{machine.policy.max_machines || 1})"
  end

  validates :fingerprint, presence: true, blank: false, uniqueness: { scope: :license_id }
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  scope :fingerprint, -> (fingerprint) { where fingerprint: fingerprint }
  scope :license, -> (id) { where license: id }
  scope :key, -> (key) { joins(:license).where licenses: { key: key } }
  scope :user, -> (id) { joins(:license).where licenses: { user_id: id } }
  scope :product, -> (id) { joins(license: [:policy]).where policies: { product_id: id } }
end

# == Schema Information
#
# Table name: machines
#
#  fingerprint :string
#  ip          :string
#  hostname    :string
#  platform    :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  name        :string
#  metadata    :jsonb
#  id          :uuid             not null, primary key
#  account_id  :uuid
#  license_id  :uuid
#
# Indexes
#
#  index_machines_on_account_id_and_created_at         (account_id,created_at)
#  index_machines_on_id_and_created_at_and_account_id  (id,created_at,account_id) UNIQUE
#  index_machines_on_license_id_and_created_at         (license_id,created_at)
#
