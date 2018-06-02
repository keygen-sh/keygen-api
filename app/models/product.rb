class Product < ApplicationRecord
  include Limitable
  include Pageable
  include Roleable
  include Searchable

  SEARCH_ATTRIBUTES = %i[id name metadata].freeze
  SEARCH_RELATIONSHIPS = {}.freeze

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
