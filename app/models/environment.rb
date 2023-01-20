class Environment < ApplicationRecord
  include Keygen::EE::ProtectedRecord[entitlements: %i[environments]]
  include Limitable
  include Orderable
  include Pageable
  include Roleable
  include Diffable

  ISOLATION_STRATEGIES = %w[
    ISOLATED
    SHARED
  ]

  has_role :environment
  has_permissions Permission::ENVIRONMENT_PERMISSIONS

  belongs_to :account
  has_many :tokens,
    dependent: :destroy,
    class_name: Token.name,
    inverse_of: :bearer,
    as: :bearer

  ##
  # _tokens association is only for cascading deletes.
  has_many :_tokens,
    dependent: :destroy_async,
    inverse_of: :environment,
    class_name: Token.name

  # TODO(ezekg) Should deleting queue up a cancelable background job?
  has_many :webhooks_endpoints, dependent: :destroy_async
  has_many :webhooks_event,     dependent: :destroy_async
  has_many :entitlements,       dependent: :destroy_async
  has_many :groups,             dependent: :destroy_async
  has_many :products,           dependent: :destroy_async
  has_many :policies,           dependent: :destroy_async
  has_many :licenses,           dependent: :destroy_async
  has_many :machines,           dependent: :destroy_async
  has_many :machine_processes,  dependent: :destroy_async
  has_many :users,              dependent: :destroy_async
  has_many :releases,           dependent: :destroy_async
  has_many :release_artifacts,  dependent: :destroy_async
  has_many :release_filetypes,  dependent: :destroy_async
  has_many :release_channels,   dependent: :destroy_async
  has_many :release_platforms,  dependent: :destroy_async
  has_many :release_arches,     dependent: :destroy_async

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

  validates :isolation_strategy,
    inclusion: { in: ISOLATION_STRATEGIES, message: 'unsupported isolation strategy' },
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
