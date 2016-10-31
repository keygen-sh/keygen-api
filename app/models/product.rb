class Product < ApplicationRecord
  include TokenAuthenticatable
  include Paginatable
  include Roleable

  belongs_to :account
  has_many :policies, dependent: :destroy
  has_many :keys, through: :policies, source: :pool
  has_many :licenses, through: :policies
  has_many :machines, through: :licenses
  has_many :users, through: :licenses
  has_one :role, as: :resource, dependent: :destroy
  has_one :token, as: :bearer, dependent: :destroy

  serialize :platforms, Array

  after_create :set_role

  validates_associated :account, message: -> (_, obj) { obj[:value].errors.full_messages.first.downcase }
  validates :account, presence: { message: "must exist" }
  validates :name, presence: true

  private

  def set_role
    grant :product
  end
end

# == Schema Information
#
# Table name: products
#
#  id         :integer          not null, primary key
#  name       :string
#  platforms  :string
#  account_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_products_on_account_id  (account_id)
#
