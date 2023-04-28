class Environment < ApplicationRecord
  include Keygen::EE::ProtectedClass[entitlements: %i[environments]]
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

  belongs_to :account
  has_many :tokens, dependent: :destroy do
    def owned = where(bearer: proxy_association.owner)
  end

  # TODO(ezekg) Should deleting queue up a cancelable background job?
  has_many :webhook_endpoints, dependent: :destroy
  has_many :webhook_event,     dependent: :destroy
  has_many :entitlements,      dependent: :destroy
  has_many :groups,            dependent: :destroy
  has_many :products,          dependent: :destroy
  has_many :policies,          dependent: :destroy
  has_many :licenses,          dependent: :destroy
  has_many :machines,          dependent: :destroy
  has_many :machine_processes, dependent: :destroy
  has_many :users,             dependent: :destroy
  has_many :releases,          dependent: :destroy
  has_many :release_artifacts, dependent: :destroy

  has_role :environment
  has_permissions Permission::ENVIRONMENT_PERMISSIONS

  accepts_nested_attributes_for :users, limit: 10
  tracks_nested_attributes_for :users

  after_initialize -> { self.isolation_strategy ||= 'ISOLATED' }

  before_validation :set_founding_users_account_and_roles!,
    if: :users_attributes_assigned?,
    on: :create

  after_commit :clear_cache!,
    on: %i[
      destroy
      update
    ]

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
    in role: { name: 'admin' }
      self.all
    in role: { name: 'environment' }
      self.where(id: accessor)
    else
      self.none
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
  # codes returns the codes of the environments.
  def self.codes = reorder(code: :asc).pluck(:code)

  private

  def set_founding_users_account_and_roles!
    users.each do |user|
      next unless
        user.new_record?

      user.assign_attributes(
        role_attributes: { name: :admin },
        account_id:,
      )
    end
  end
end
