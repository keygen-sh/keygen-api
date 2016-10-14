class Key < ApplicationRecord
  include Paginatable

  belongs_to :account
  belongs_to :policy
  has_one :product, through: :policy

  validates :account, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }

  validates :key, presence: true, blank: false,
    uniqueness: { scope: :policy_id }

  scope :policy, -> (id) { where policy: Policy.decode_id(id) }
  scope :product, -> (id) { joins(:policy).where policies: { product_id: Product.decode_id(id) } }
end
