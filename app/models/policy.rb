class Policy < ApplicationRecord
  include Paginatable

  belongs_to :account
  belongs_to :product
  has_many :licenses, dependent: :destroy
  has_many :pool, class_name: "Key", dependent: :destroy

  validates_associated :account, message: -> (_, obj) { obj[:value].errors.full_messages.first.downcase }
  validates :account, presence: { message: "must exist" }
  validates :product, presence: { message: "must exist" }

  scope :product, -> (id) { where product: Product.decode_id(id) }

  def pool?
    use_pool
  end

  def pop!
    return nil if pool.empty?
    key = pool.first.destroy
    return key
  rescue ActiveRecord::StaleObjectError
    reload
    retry
  end
end
