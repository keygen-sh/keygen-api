class Product < ApplicationRecord
  include Limitable
  include Pageable
  include Roleable

  belongs_to :account
  has_many :policies, dependent: :destroy
  has_many :keys, through: :policies, source: :pool
  has_many :licenses, through: :policies
  has_many :machines, -> { distinct }, through: :licenses
  has_many :users, -> { distinct }, through: :licenses
  has_many :tokens, as: :bearer, dependent: :destroy
  has_one :role, as: :resource, dependent: :destroy

  after_create :set_role

  validates :account, presence: { message: "must exist" }
  validates :name, presence: true
  validates :url, url: { protocols: %w[https http] }, allow_nil: true
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  private

  def set_role
    grant :product
  end
end

# == Schema Information
#
# Table name: products
#
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  platforms  :jsonb
#  metadata   :jsonb
#  id         :uuid             not null, primary key
#  account_id :uuid
#  url        :string
#
# Indexes
#
#  index_products_on_account_id_and_created_at         (account_id,created_at)
#  index_products_on_id_and_created_at_and_account_id  (id,created_at,account_id) UNIQUE
#
