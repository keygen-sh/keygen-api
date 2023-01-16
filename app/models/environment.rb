class Environment < ApplicationRecord
  include Keygen::EE::ProtectedRecord[entitlements: %i[environments]]
  include Limitable
  include Orderable
  include Pageable
  include Roleable
  include Diffable

  has_role :environment
  has_permissions Permission::ENVIRONMENT_PERMISSIONS

  belongs_to :account
  has_many :tokens,
    dependent: :destroy,
    as: :bearer

  before_create -> { self.isolation_strategy ||= 'ISOLATED' }

  after_commit :clear_cache!,
    on: %i[
      destroy
      update
    ]

  validates :code,
    uniqueness: { case_sensitive: false, scope: :account_id },
    length: { minimum: 1, maximum: 255 },
    format: { without: UUID_RE },
    allow_blank: false,
    presence: true

  validates :name,
    length: { minimum: 1, maximum: 255 },
    allow_blank: false,
    presence: true

  def self.cache_key(key, account:)      = [:envs, account.id, key, CACHE_KEY_VERSION].join(':')
  def self.clear_cache!(*keys, account:) = keys.each { Rails.cache.delete(cache_key(_1, account:)) }

  def cache_key    = Environment.cache_key(id, account:)
  def clear_cache! = Environment.clear_cache!(id, code, account:)

  def isolated? = isolation_strategy == 'ISOLATED'
  def shared?   = isolation_strategy == 'SHARED'

  ##
  # codes returns the codes of the environments.
  def self.codes = reorder(code: :asc).pluck(:code)
end
