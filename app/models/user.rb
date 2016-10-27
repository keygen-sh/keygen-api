class User < ApplicationRecord
  ALLOWED_ROLES = %w[admin user].freeze

  include TokenAuthenticatable
  include PasswordResetable
  include Paginatable
  include Roleable

  has_secure_password

  belongs_to :account
  has_many :licenses, dependent: :destroy
  has_many :products, through: :licenses
  has_many :machines, through: :licenses
  has_one :role, as: :resource, dependent: :destroy
  has_one :token, as: :bearer, dependent: :destroy

  accepts_nested_attributes_for :role

  serialize :meta, Hash

  before_save -> { self.email = email.downcase }
  after_create :set_role, if: -> { role.nil? }

  validates_associated :account, message: -> (_, obj) { obj[:value].errors.full_messages.first.downcase }
  validates :name, presence: true
  validates :email, email: true, presence: true, length: { maximum: 255 }, uniqueness: { case_sensitive: false, scope: :account_id }

  scope :roles, -> (*roles) { joins(:role).where roles: { name: roles } }
  scope :product, -> (id) { joins(licenses: [:policy]).where policies: { product_id: Product.decode_id(id) } }
  scope :admins, -> { roles :admin }

  private

  def set_role
    grant :user
  end
end
