class Key < ApplicationRecord
  belongs_to :account
  belongs_to :policy
  has_one :product, through: :policy

  validates :account, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }

  validates :key, presence: true, blank: false,
    uniqueness: { scope: :policy_id }

  scope :policy, -> (id) {
    where policy: Policy.find_by_hashid(id)
  }
  scope :page, -> (page = {}) {
    paginate(page[:number]).per page[:size]
  }
  scope :product, -> (id) {
    joins(:policy).where policies: { product_id: Product.find_by_hashid(id) }
  }
end
