class Policy < ApplicationRecord
  belongs_to :account
  belongs_to :product
  has_many :licenses, dependent: :destroy

  serialize :pool, Array

  validates_associated :account, message: -> (_, obj) { obj[:value].errors.full_messages.first }
  validates :account, presence: { message: "must exist" }
  validates :product, presence: { message: "must exist" }

  scope :product, -> (id) {
    where product: Product.find_by_hashid(id)
  }

  def pool?
    use_pool
  end

  def pool_pop
    begin
      return nil if pool.empty?
      key = pool.pop
      self.save!
      return key
    rescue ActiveRecord::StaleObjectError
      self.reload
      retry
    end
  end

  def pool_delete(key)
    begin
      pool.delete key
      self.save!
    rescue ActiveRecord::StaleObjectError
      self.reload
      retry
    end
  end

  def pool_push(key)
    begin
      pool << key
      self.save!
    rescue ActiveRecord::StaleObjectError
      self.reload
      retry
    end
  end
end
