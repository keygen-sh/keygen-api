class User < ApplicationRecord
  include PasswordReset
  include AuthToken

  has_secure_password

  belongs_to :account
  has_and_belongs_to_many :products
  has_many :licenses, dependent: :destroy
  # has_one :billing, as: :customer

  before_create -> { self.email = email.downcase }

  validates_associated :account, message: -> (_, obj) { obj[:value].errors.full_messages.first }
  # validates :account, presence: { message: "must exist" }
  validates :name, presence: true
  validates :email,
    presence: true,
    length: { maximum: 255 },
    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
    uniqueness: { case_sensitive: false, scope: :account_id }

  scope :products, -> (ids) {
    includes(:products).where products: { id: ids.map { |id| Product.decode_id(id) || "" } }
  }
  scope :page, -> (page = {}) {
    paginate(page[:number]).per page[:size]
  }

  def admin?
    self.role == "admin"
  end
end
