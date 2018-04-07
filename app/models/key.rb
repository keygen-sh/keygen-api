class Key < ApplicationRecord
  include Limitable
  include Pageable
  include Searchable

  EXCLUDED_KEYS = %w[actions action].freeze

  belongs_to :account
  belongs_to :policy
  has_one :product, through: :policy

  search(
    attributes: [:id, :key],
    relationships: {
      product: [:id, :name],
      policy: [:id, :name]
    }
  )

  validates :account, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }

  validates :key, presence: true, blank: false, uniqueness: { case_sensitive: true, scope: :account_id }, exclusion: { in: Sluggable::EXCLUDED_SLUGS, message: "is reserved" }

  validate on: :create do
    errors.add :policy, "cannot be added to an unpooled policy" if !policy.nil? && !policy.pool?
  end

  validate on: [:create, :update] do
    errors.add :key, "must not conflict with another license's identifier (UUID)" if account.licenses.exists? key
    errors.add :key, "is already being used as a license's key" if account.licenses.exists? key: key
  end

  scope :policy, -> (id) { where policy: id }
  scope :product, -> (id) { joins(:policy).where policies: { product_id: id } }
end

# == Schema Information
#
# Table name: keys
#
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  id         :uuid             not null, primary key
#  policy_id  :uuid
#  account_id :uuid
#  tsv_id     :tsvector
#  tsv_key    :tsvector
#
# Indexes
#
#  index_keys_on_account_id_and_created_at         (account_id,created_at)
#  index_keys_on_id_and_created_at_and_account_id  (id,created_at,account_id) UNIQUE
#  index_keys_on_policy_id_and_created_at          (policy_id,created_at)
#  index_keys_on_tsv_id                            (tsv_id)
#  index_keys_on_tsv_key                           (tsv_key)
#
