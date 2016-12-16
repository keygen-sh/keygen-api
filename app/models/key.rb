class Key < ApplicationRecord
  include Limitable
  include Pageable

  acts_as_paranoid

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
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  id         :uuid             not null, primary key
#  policy_id  :uuid
#  account_id :uuid
#
# Indexes
#
#  index_keys_on_account_id  (account_id)
#  index_keys_on_created_at  (created_at)
#  index_keys_on_deleted_at  (deleted_at)
#  index_keys_on_policy_id   (policy_id)
#
