class Policy < ApplicationRecord
  belongs_to :account
  belongs_to :product
  has_many :licenses, dependent: :destroy
  has_many :pool, foreign_key: "policy_id", class_name: "Key", dependent: :destroy

  validates_associated :account, message: -> (_, obj) { obj[:value].errors.full_messages.first.downcase }
  validates :account, presence: { message: "must exist" }
  validates :product, presence: { message: "must exist" }

  scope :product, -> (id) {
    where product: Product.find_by_hashid(id)
  }
  scope :page, -> (page = {}) {
    paginate(page[:number]).per page[:size]
  }

  def pool?
    use_pool
  end

  def pop!
    return nil if pool.empty?
    key = pool.first.destroy
    self.save!
    return key
  rescue ActiveRecord::StaleObjectError
    self.reload
    retry
  end
end
