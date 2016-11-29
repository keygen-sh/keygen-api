class Key < ApplicationRecord
  include Paginatable
  include Limitable

  acts_as_paranoid

  belongs_to :account
  belongs_to :policy
  has_one :product, through: :policy

  validates :account, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }

  validates :key, presence: true, blank: false, uniqueness: { scope: :policy_id }

  scope :policy, -> (id) { where policy: Policy.decode_id(id) }
  scope :product, -> (id) { joins(:policy).where policies: { product_id: Product.decode_id(id) } }
end

# == Schema Information
#
# Table name: keys
#
#  id         :integer          not null, primary key
#  key        :string
#  policy_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer
#  deleted_at :datetime
#
# Indexes
#
#  index_keys_on_account_id_and_id         (account_id,id)
#  index_keys_on_deleted_at                (deleted_at)
#  index_keys_on_policy_id_and_account_id  (policy_id,account_id)
#
