class Environment < ApplicationRecord
  include Keygen::EE::ProtectedClass[entitlements: %i[environments]]
  include Keygen::PortableClass
  include Accountable
  include Limitable
  include Orderable
  include Dirtyable
  include Pageable
  include Roleable
  include Diffable

  ISOLATION_STRATEGIES = %w[
    ISOLATED
    SHARED
  ].freeze

  has_many :tokens, dependent: :destroy_async do
    def owned = where(bearer: proxy_association.owner)
  end

  # TODO(ezekg) Should deleting queue up a cancelable background job?
  has_many :webhook_endpoints,  dependent: :destroy_async
  has_many :webhook_events,     dependent: :destroy_async
  has_many :entitlements,       dependent: :destroy_async
  has_many :groups,             dependent: :destroy_async
  has_many :products,           dependent: :destroy_async
  has_many :policies,           dependent: :destroy_async
  has_many :licenses,           dependent: :destroy_async
  has_many :license_users,      dependent: :destroy_async
  has_many :machines,           dependent: :destroy_async
  has_many :machine_processes,  dependent: :destroy_async
  has_many :machine_components, dependent: :destroy_async
  has_many :users,              dependent: :destroy_async
  has_many :releases,           dependent: :destroy_async
  has_many :release_artifacts,  dependent: :destroy_async

  has_account
  has_role :environment
  has_permissions Permission::ENVIRONMENT_PERMISSIONS

  accepts_nested_attributes_for :users, limit: 10
  tracks_nested_attributes_for :users

  after_initialize -> { self.isolation_strategy ||= 'ISOLATED' }

  before_validation :set_founding_nested_users_to_admins!,
    if: :users_attributes_assigned?,
    on: :create

  after_commit :clear_cache!,
    on: %i[
      destroy
      update
    ]

  validate :enforce_founding_admins!,
    if: :isolated?,
    on: :create

  validates :code,
    exclusion: { in: EXCLUDED_ALIASES, message: 'is reserved' },
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

  scope :accessible_by, -> accessor {
    case accessor
    in role: Role(:admin)
      all
    in role: Role(:environment)
      where(id: accessor)
    else
      none
    end
  }

  scope :isolated, -> {
    where(isolation_strategy: 'ISOLATED')
  }

  scope :shared, -> {
    where(isolation_strategy: 'SHARED')
  }

  def self.cache_key(key, account:)      = [:envs, account.id, key, CACHE_KEY_VERSION].join(':')
  def self.clear_cache!(*keys, account:) = keys.each { Rails.cache.delete(cache_key(_1, account:)) }

  def cache_key    = Environment.cache_key(id, account:)
  def clear_cache! = Environment.clear_cache!(id, code, account:)

  def isolated? = isolation_strategy == 'ISOLATED'
  def shared?   = isolation_strategy == 'SHARED'

  ##
  # admins returns the admins accessible from the environment.
  def admins = account.admins.for_environment(self, strict: false)

  ##
  # codes returns the codes of the environments.
  def self.codes = reorder(code: :asc).pluck(:code)

  private

  def set_founding_nested_users_to_admins!
    users.each do |user|
      next unless
        user.new_record?

      user.assign_attributes(
        role_attributes: { name: :admin },
        account_id:,
      )
    end
  end

  def enforce_founding_admins!
    return if
      users.count(&:admin?) >= User::MINIMUM_ADMIN_COUNT

    errors.add :admins, :required, message: "environment must have at least #{User::MINIMUM_ADMIN_COUNT} admin user"

    throw :abort
  end
end
