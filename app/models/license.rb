class License < ApplicationRecord
  include Limitable
  include Tokenable
  include Pageable
  include Roleable
  include Searchable

  EXCLUDED_KEYS = %w[actions action].freeze
  SEARCH_ATTRIBUTES = %i[id key metadata].freeze
  SEARCH_RELATIONSHIPS = {
    product: %i[id name],
    policy: %i[id name],
    user: %i[id email]
  }

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  belongs_to :account
  belongs_to :user
  belongs_to :policy
  has_many :tokens, as: :bearer, dependent: :destroy
  has_many :machines, dependent: :destroy
  has_one :product, through: :policy
  has_one :role, as: :resource, dependent: :destroy

  attr_reader :raw

  before_create :set_first_check_in, if: -> { requires_check_in? }
  before_create :set_expiry, unless: -> { policy.nil? }
  after_create :set_key, unless: -> { key.present? || policy.nil? }
  after_create :set_role

  validates :account, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }

  validate on: :create do
    errors.add :key, :conflict, message: "must not conflict with another license's identifier (UUID)" if account.licenses.exists? key
    errors.add :key, :not_supported, message: "cannot be specified for an encrypted license" if key.present? && policy.encrypted?
  end

  validate on: :update do |license|
    next if license&.uses.nil? || license.policy&.max_uses.nil?
    next if license.uses <= license.policy.max_uses

    license.errors.add :uses, :limit_exceeded, message: "usage exceeds maximum allowed by current policy (#{license.policy.max_uses})"
  end

  validates :key, uniqueness: { case_sensitive: true, scope: :account_id }, exclusion: { in: Sluggable::EXCLUDED_SLUGS, message: "is reserved" }, unless: -> { key.nil? }
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }
  validates :uses, numericality: { greater_than_or_equal_to: 0 }

  scope :suspended, -> (status = true) { where suspended: ActiveRecord::Type::Boolean.new.cast(status) }
  scope :policy, -> (id) { where policy: id }
  scope :user, -> (id) { where user: id }
  scope :product, -> (id) { joins(:policy).where policies: { product_id: id } }
  scope :machine, -> (id) { joins(:machines).where machines: { id: id } }
  scope :fingerprint, -> (fp) { joins(:machines).where machines: { fingerprint: fp } }

  delegate :requires_check_in?, to: :policy
  delegate :check_in_interval, to: :policy
  delegate :check_in_interval_count, to: :policy

  def suspended?
    suspended
  end

  def expired?
    return false if expiry.nil?

    expiry < Time.current
  end

  def check_in_overdue?
    return false unless requires_check_in?

    last_check_in_at < check_in_interval_count.send(check_in_interval).ago
  rescue NoMethodError
    nil
  end

  def next_check_in_at
    return nil unless requires_check_in?

    last_check_in_at + check_in_interval_count.send(check_in_interval) rescue nil
  end

  def check_in!
    return false unless requires_check_in?

    self.last_check_in_at = Time.current
    save
  end

  def renew!
    return false if expiry.nil?

    self.expiry += policy.duration
    save
  end

  def suspend!
    self.suspended = true
    save
  end

  def reinstate!
    self.suspended = false
    save
  end

  private

  def set_role
    grant :license
  end

  def set_first_check_in
    self.last_check_in_at = Time.current
  end

  def set_key
    case
    when policy.pool?
      if item = policy.pop!
        self.key = item.key
      else
        errors.add :policy, :pool_empty, message: "pool is empty"
      end
    when policy.encrypted?
      @raw, enc = generate_hashed_token :key, version: "v1" do |token|
        # Replace first n characters with our id so that we can do a lookup
        # on the encrypted key
        token.gsub(/\A.{#{UUID_LENGTH}}/, id.delete("-"))
             .scan(/.{#{UUID_LENGTH}}/).join "-"
      end

      self.key = enc
    else
      self.key = generate_token :key do |token|
        token.gsub(/\A.{#{UUID_LENGTH}}/, id.delete("-"))
             .scan(/.{#{UUID_LENGTH}}/).join "-"
      end
    end

    # We're raising a RecordInvalid exception so that the transaction will be
    # halted and rolled back (since our record is invalid without a key)
    raise ActiveRecord::RecordInvalid if key.nil?

    save
  end

  def set_expiry
    if policy.duration.nil?
      self.expiry = nil
    else
      self.expiry = Time.current + policy.duration
    end
  end
end
