class Policy < ApplicationRecord
  belongs_to :account
  belongs_to :product
  has_many :licenses, dependent: :destroy

  serialize :pool, Array

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

  def pool_pop
    return nil if pool.empty?
    key = pool.pop
    self.save!
    return key
  rescue ActiveRecord::StaleObjectError
    self.reload
    retry
  end

  def pool_delete(key)
    pool.delete key
    self.save!
  rescue ActiveRecord::StaleObjectError
    self.reload
    retry
  end

  def pool_push(key)
    pool << key
    self.save!
  rescue ActiveRecord::StaleObjectError
    self.reload
    retry
  end
end
