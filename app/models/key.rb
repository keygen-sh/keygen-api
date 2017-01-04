class Key < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :policy
  has_one :product, through: :policy

  validates :account, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }

  validates :key, presence: true, blank: false, uniqueness: { scope: :policy_id }

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
#  index_keys_on_account_id  (account_id)
#  index_keys_on_created_at  (created_at)
#  index_keys_on_policy_id   (policy_id)
#
