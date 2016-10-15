class Product < ApplicationRecord
  include TokenAuthenticatable
  include Resourcifiable
  include Paginatable

  belongs_to :account
  has_many :policies, dependent: :destroy
  has_many :keys, through: :policies, source: :pool
  has_many :licenses, through: :policies
  has_many :machines, through: :licenses
  has_many :users, through: :licenses
  has_one :token, as: :bearer, dependent: :destroy

  serialize :platforms, Array

  before_create :set_roles

  validates_associated :account, message: -> (_, obj) { obj[:value].errors.full_messages.first.downcase }
  validates :account, presence: { message: "must exist" }
  validates :name, presence: true

  private

  def set_roles
    add_role :product
  end
end
