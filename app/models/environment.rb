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

  belongs_to :account
  has_many :tokens,
    class_name: Token.name,
    inverse_of: :bearer,
    dependent: :destroy,
    as: :bearer

  ##
  # _tokens association is only for cascading deletes.
  has_many :_tokens,
    class_name: Token.name,
    inverse_of: :environment,
    dependent: :nullify

  # TODO(ezekg) Should deleting queue up a cancelable background job?
  has_many :webhooks_endpoints, dependent: :nullify
  has_many :webhooks_event,     dependent: :nullify
  has_many :entitlements,       dependent: :nullify
  has_many :groups,             dependent: :nullify
  has_many :products,           dependent: :nullify
  has_many :policies,           dependent: :nullify
  has_many :licenses,           dependent: :nullify
  has_many :machines,           dependent: :nullify
  has_many :machine_processes,  dependent: :nullify
  has_many :users,              dependent: :nullify
  has_many :releases,           dependent: :nullify
  has_many :release_artifacts,  dependent: :nullify
  has_many :release_filetypes,  dependent: :nullify
  has_many :release_channels,   dependent: :nullify
  has_many :release_platforms,  dependent: :nullify
  has_many :release_arches,     dependent: :nullify

  has_role :environment
  has_permissions Permission::ENVIRONMENT_PERMISSIONS

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
