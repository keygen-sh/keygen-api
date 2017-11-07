class Key < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :policy
  has_one :product, through: :policy

  validates :account, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }

  validates :key, presence: true, blank: false, uniqueness: { case_sensitive: true, scope: :account_id }

  validate on: :create do
    errors.add :policy, "cannot add key to an unpooled policy" unless policy.pool?
  end

  validate on: [:create, :update] do
    errors.add :key, "a license already exists with this key" if account.licenses.exists? key: key
  end

  scope :policy, -> (id) { where policy: id }
  scope :product, -> (id) { joins(:policy).where policies: { product_id: id } }
end

# == Schema Information
#
# Table name: keys
#
#  id         :uuid             not null, primary key
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  policy_id  :uuid
#  account_id :uuid
#
# Indexes
#
#  index_keys_on_created_at_and_account_id  (created_at,account_id)
#  index_keys_on_created_at_and_id          (created_at,id) UNIQUE
#  index_keys_on_created_at_and_policy_id   (created_at,policy_id)
#  index_keys_on_id                         (id) UNIQUE
#
