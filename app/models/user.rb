class User < ApplicationRecord
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

  before_save -> { self.email = email.downcase }
  after_create :set_role, if: -> { role.nil? }

  validates :name, presence: true
  validates :email, email: true, presence: true, length: { maximum: 255 }, uniqueness: { case_sensitive: false, scope: :account_id }

  scope :roles, -> (*roles) { joins(:role).where roles: { name: roles } }
  scope :product, -> (id) { joins(licenses: [:policy]).where policies: { product_id: id } }
  scope :admins, -> { roles :admin }

  private

  def set_role
    grant :user
  end
end

# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  name                   :string
#  email                  :string
#  password_digest        :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  password_reset_token   :string
#  password_reset_sent_at :datetime
#  metadata               :jsonb
#  account_id             :uuid
#
# Indexes
#
#  index_users_on_account_id  (account_id)
#  index_users_on_created_at  (created_at)
#
