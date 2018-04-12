class Product < ApplicationRecord
  include Limitable
  include Pageable
  include Roleable
  include Searchable

  SEARCH_ATTRIBUTES = %i[id name metadata].freeze

  search attributes: SEARCH_ATTRIBUTES

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
#  id           :uuid             not null, primary key
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  platforms    :jsonb
#  metadata     :jsonb
#  account_id   :uuid
#  url          :string
#  tsv_id       :tsvector
#  tsv_name     :tsvector
#  tsv_metadata :tsvector
#
# Indexes
#
#  index_products_on_account_id_and_created_at         (account_id,created_at)
#  index_products_on_id_and_created_at_and_account_id  (id,created_at,account_id) UNIQUE
#  index_products_on_tsv_id                            (tsv_id)
#  index_products_on_tsv_metadata                      (tsv_metadata)
#  index_products_on_tsv_name                          (tsv_name)
#
