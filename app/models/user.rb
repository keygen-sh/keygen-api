class User < ApplicationRecord
  include TokenAuthenticatable
  include PasswordResetable
  include Resourcifiable
  include Paginatable

  has_secure_password

  belongs_to :account
  has_and_belongs_to_many :products
  has_many :licenses, dependent: :destroy
  has_many :machines, through: :licenses
  has_one :token, as: :bearer, dependent: :destroy

  serialize :meta, Hash

  accepts_nested_attributes_for :roles

  before_save -> { self.email = email.downcase }
  before_create :set_roles

  validates_associated :account, message: -> (_, obj) { obj[:value].errors.full_messages.first.downcase }
  validates :name, presence: true
  validates :email,
    presence: true,
    length: { maximum: 255 },
    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
    uniqueness: { case_sensitive: false, scope: :account_id }

  scope :roles, -> (*roles) { joins(token: [:roles]).where roles: { name: roles } }
  scope :product, -> (id) { joins(:products).where products_users: { product_id: Product.decode_id(id) } }
  scope :admins, -> { roles :admin }

  private

  def set_roles
    add_role :user
  end
end
