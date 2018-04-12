class Policy < ApplicationRecord
  include Limitable
  include Pageable
  include Searchable

  SEARCH_ATTRIBUTES = %i[id name metadata].freeze
  SEARCH_RELATIONSHIPS = {
    product: %i[id name]
  }.freeze

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  belongs_to :account
  belongs_to :product
  has_many :licenses, dependent: :destroy
  has_many :pool, class_name: "Key", dependent: :destroy

  before_create -> { self.protected = account.protected? }, if: -> { protected.nil? }

  validates :account, presence: { message: "must exist" }
  validates :product, presence: { message: "must exist" }

  validates :name, presence: true
  validates :max_machines, numericality: { greater_than_or_equal_to: 1, message: "must be greater than or equal to 1 for floating policy" }, allow_nil: true, if: :floating?
  validates :max_machines, numericality: { equal_to: 1, message: "must be equal to 1 for non-floating policy" }, allow_nil: true, if: :node_locked?
  validates :duration, numericality: { greater_than_or_equal_to: 1.day.to_i, message: "must be greater than or equal to 86400 (1 day)" }, allow_nil: true
  validates :check_in_interval, inclusion: { in: %w[day week month year], message: "must be one of: day, week, month, year" }, if: :requires_check_in?
  validates :check_in_interval_count, inclusion: { in: 1..365, message: "must be a number between 1 and 365 inclusive" }, if: :requires_check_in?
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  validate do
    errors.add :encrypted, "cannot be encrypted and use a pool" if pool? && encrypted?
  end

  scope :product, -> (id) { where product: id }

  def pool?
    use_pool
  end

  def strict?
    strict
  end

  def floating?
    floating
  end

  def node_locked?
    !floating
  end

  def encrypted?
    encrypted
  end

  def protected?
    protected
  end

  def requires_check_in?
    require_check_in
  end

  def pop!
    return nil if pool.empty?
    key = pool.first.destroy
    return key
  rescue ActiveRecord::StaleObjectError
    reload
    retry
  end
end

# == Schema Information
#
# Table name: policies
#
#  name                      :string
#  duration                  :integer
#  strict                    :boolean          default(FALSE)
#  floating                  :boolean          default(FALSE)
#  use_pool                  :boolean          default(FALSE)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  lock_version              :integer          default(0), not null
#  max_machines              :integer
#  encrypted                 :boolean          default(FALSE)
#  protected                 :boolean
#  metadata                  :jsonb
#  id                        :uuid             not null, primary key
#  product_id                :uuid
#  account_id                :uuid
#  check_in_interval         :string
#  check_in_interval_count   :integer
#  require_check_in          :boolean          default(FALSE)
#  require_product_scope     :boolean          default(FALSE)
#  require_policy_scope      :boolean          default(FALSE)
#  require_machine_scope     :boolean          default(FALSE)
#  require_fingerprint_scope :boolean          default(FALSE)
#  concurrent                :boolean          default(TRUE)
#  max_uses                  :integer
#  tsv_id                    :tsvector
#  tsv_name                  :tsvector
#  tsv_metadata              :tsvector
#
# Indexes
#
#  index_policies_on_account_id_and_created_at         (account_id,created_at)
#  index_policies_on_id_and_created_at_and_account_id  (id,created_at,account_id) UNIQUE
#  index_policies_on_product_id_and_created_at         (product_id,created_at)
#  index_policies_on_tsv_id                            (tsv_id)
#  index_policies_on_tsv_metadata                      (tsv_metadata)
#  index_policies_on_tsv_name                          (tsv_name)
#
