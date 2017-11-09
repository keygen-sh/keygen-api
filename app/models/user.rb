class User < ApplicationRecord
  MINIMUM_ADMIN_COUNT = 1

  include PasswordResetable
  include Limitable
  include Pageable
  include Roleable

  has_secure_password

  belongs_to :account
  has_many :licenses, dependent: :destroy
  has_many :products, -> { distinct }, through: :licenses
  has_many :machines, through: :licenses
  has_many :tokens, as: :bearer, dependent: :destroy
  has_one :role, as: :resource, dependent: :destroy

  accepts_nested_attributes_for :role

  before_destroy :enforce_admin_minimum_on_account
  before_save -> { self.email = email.downcase }
  after_create :set_role, if: -> { role.nil? }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, email: true, presence: true, length: { maximum: 255 }, uniqueness: { case_sensitive: false, scope: :account_id }

  scope :roles, -> (*roles) { joins(:role).where roles: { name: roles } }
  scope :product, -> (id) { joins(licenses: [:policy]).where policies: { product_id: id } }
  scope :admins, -> { roles :admin }

  def full_name
    [first_name, last_name].join " "
  end

  private

  def set_role
    grant :user
  end

  def enforce_admin_minimum_on_account
    return if account.admins.size >= MINIMUM_ADMIN_COUNT

    errors.add :account, "account must have at least one admin user"

    throw :abort
  end
end

# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  email                  :string
#  password_digest        :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  password_reset_token   :string
#  password_reset_sent_at :datetime
#  metadata               :jsonb
#  account_id             :uuid
#  first_name             :string
#  last_name              :string
#
# Indexes
#
#  index_users_on_account_id_and_created_at            (account_id,created_at)
#  index_users_on_email_and_account_id_and_created_at  (email,account_id,created_at)
#  index_users_on_id_and_created_at_and_account_id     (id,created_at,account_id) UNIQUE
#
