# frozen_string_literal: true

class User < ApplicationRecord
  MINIMUM_ADMIN_COUNT = 1

  include PasswordResettable
  include Limitable
  include Orderable
  include Pageable
  include Roleable
  include Diffable

  has_secure_password :password, validations: false

  belongs_to :account
  belongs_to :group,
    optional: true
  has_one :role, as: :resource, dependent: :destroy
  has_many :second_factors, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_many :products, -> { select('"products".*, "products"."id", "products"."created_at"').distinct('"products"."id"').reorder(Arel.sql('"products"."created_at" ASC')) }, through: :licenses
  has_many :license_entitlements, through: :licenses
  has_many :policy_entitlements, through: :licenses
  has_many :machines, through: :licenses
  has_many :tokens, as: :bearer, dependent: :destroy_async
  has_many :releases, -> u { for_user(u.id) },
    through: :products
  has_many :event_logs,
    as: :resource
  has_many :group_owners
  has_many :groups,
    through: :group_owners

  accepts_nested_attributes_for :role, update_only: true

  before_destroy :enforce_admin_minimum_on_account!
  before_update :enforce_admin_minimum_on_account!, if: -> { role.present? && role.changed? }
  before_create :set_user_role!, if: -> { role.nil? }

  before_save -> { self.email = email.downcase.strip }

  validates :group,
    presence: { message: 'must exist' },
    scope: { by: :account_id },
    unless: -> {
      group_id_before_type_cast.nil?
    }

  validates :email, email: true, presence: true, length: { maximum: 255 }, uniqueness: { case_sensitive: false, scope: :account_id }
  validates :password, length: { minimum: 6, maximum: 72.bytes }, allow_nil: true
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  validate on: %i[create update] do
    next unless
      group_id_changed?

    next unless
      group.present? && group.max_users.present?

    next unless
      group.users.count >= group.max_users

    errors.add :group, :user_limit_exceeded, message: "user count has exceeded maximum allowed by current group (#{group.max_users})"
  end

  scope :stdout_subscribers, -> {
    User.distinct_on(:email)
        .where(account: Account.active, stdout_unsubscribed_at: nil)
        .with_roles(:admin, :developer)
        .reorder(:email, :created_at)
  }

  scope :search_email, -> (term) {
    where('users.email ILIKE ?', "%#{term}%")
  }

  scope :search_first_name, -> (term) {
    where('users.first_name ILIKE ?', "%#{term}%")
  }

  scope :search_last_name, -> (term) {
    where('users.last_name ILIKE ?', "%#{term}%")
  }

  scope :search_full_name, -> (term) {
    first_name, last_name = term.to_s.split(' ', 2)

    search_first_name(first_name).search_last_name(last_name)
  }

  scope :search_name, -> (term) {
    search_full_name(term)
  }

  scope :search_metadata, -> (terms) {
    # FIXME(ezekg) Duplicated code for licenses, users, and machines.
    # FIXME(ezekg) Need to figure out a better way to do this. We need to be able
    #              to search for the original string values and type cast, since
    #              HTTP querystring parameters are strings.
    #
    #              Example we need to be able to search for:
    #
    #                { metadata: { external_id: "1624214616", internal_id: 1 } }
    #
    terms.reduce(self) do |scope, (key, value)|
      search_key       = key.to_s.underscore.parameterize(separator: '_')
      before_type_cast = { search_key => value }
      after_type_cast  =
        case value
        when 'true'
          { search_key => true }
        when 'false'
          { search_key => false }
        when 'null'
          { search_key => nil }
        when /^\d+$/
          { search_key => value.to_i }
        when /^\d+\.\d+$/
          { search_key => value.to_f }
        else
          { search_key => value }
        end

      scope.where('"users"."metadata" @> ?', before_type_cast.to_json)
        .or(
          scope.where('"users"."metadata" @> ?', after_type_cast.to_json)
        )
    end
  }

  scope :search_role, -> (term) {
    role_identifier = term.to_s
    return none if
      role_identifier.empty?

    return joins(:role).where(role: { id: role_identifier }) if
      UUID_RE.match?(role_identifier)

    scope = joins(:role).where('roles.name ILIKE ?', "%#{role_identifier}%")
    return scope unless
      UUID_CHAR_RE.match?(role_identifier)

    scope.or(
      joins(:role).where(<<~SQL.squish, role_identifier.gsub(SANITIZE_TSV_RE, ' '))
        to_tsvector('simple', roles.id::text)
        @@
        to_tsquery(
          'simple',
          ''' ' ||
          ?     ||
          ' ''' ||
          ':*'
        )
      SQL
    )
  }

  scope :with_metadata, -> (meta) { search_metadata meta }
  scope :with_roles, -> (*roles) { joins(:role).where roles: { name: roles.flatten.map { |r| r.to_s.underscore } } }
  scope :with_role, -> (role) { joins(:role).where(roles: { name: role.to_s.underscore }) }
  scope :with_status, -> status {
    case status.to_s.upcase
    when 'BANNED'
      self.banned
    when 'INACTIVE'
      self.inactive
    when 'ACTIVE'
      self.active
    else
      self.none
    end
  }
  scope :for_product, -> (id) { joins(licenses: [:policy]).where policies: { product_id: id } }
  scope :for_license, -> (id) { joins(:licenses).where licenses: id }
  scope :for_owner, -> id { joins(group: :owners).where(group: { group_owners: { user_id: id } }) }
  scope :for_user, -> (id) { where(id: id).union(for_owner(id)).distinct }
  scope :for_group, -> id { where(group: id) }
  scope :administrators, -> { with_roles(:admin, :developer, :read_only, :sales_agent, :support_agent) }
  scope :admins, -> { with_role(:admin) }
  scope :banned, -> { where.not(banned_at: nil) }
  scope :active, -> (t = 90.days.ago) {
    where('users.created_at >= ?', t)
      .where(banned_at: nil)
      .union(
        joins(:licenses)
          .where(banned_at: nil)
          .where(
            'licenses.created_at >= :t OR licenses.last_validated_at >= :t',
            t: t,
          )
      )
  }
  scope :inactive, -> (t = 90.days.ago) {
    where('users.created_at < ?', t)
      .where.missing(:licenses)
      .where(banned_at: nil)
      .union(
        joins(:licenses)
          .where('users.created_at < ?', t)
          .where(banned_at: nil)
          .where(
            'licenses.created_at < :t AND (licenses.last_validated_at IS NULL OR licenses.last_validated_at < :t)',
            t: t,
          )
      )
  }
  scope :assigned, -> (status = true) {
    sub_query = License.where('licenses.user_id = users.id').select(1).arel.exists

    if ActiveRecord::Type::Boolean.new.cast(status)
      where(sub_query)
    else
      where.not(sub_query)
    end
  }

  def entitlements
    entl = Entitlement.where(account_id: account_id).distinct

    entl.left_outer_joins(:policy_entitlements, :license_entitlements)
        .where(policy_entitlements: { policy_id: licenses.reorder(nil).select(:policy_id) })
        .or(
          entl.where(license_entitlements: { license_id: licenses.reorder(nil).select(:id) })
        )
  end

  def full_name
    return nil if first_name.nil? || last_name.nil?

    [first_name, last_name].join " "
  end

  def parsed_email
    return nil if email.nil?

    user, host = email.downcase.match(/([^@]+)@(.+)/).captures

    {
      user: user,
      host: host,
    }
  end

  def password?
    password_digest?
  end

  def active?(t = 90.days.ago)
    created_at >= t || licenses.active.any?
  end

  def inactive?(t = 90.days.ago)
    created_at < t && licenses.active.empty?
  end

  def banned?
    banned_at?
  end

  def ban!
    update!(banned_at: Time.current)
  end

  def unban!
    update!(banned_at: nil)
  end

  def status
    case
    when banned?
      :BANNED
    when active?
      :ACTIVE
    else
      :INACTIVE
    end
  end

  def second_factor_enabled?
    return false if second_factors.enabled.empty?

    # We only allow a single 2FA key right now, but we may allow more later,
    # e.g. multiple 2FA keys, or U2F.
    second_factor = second_factors.enabled.last

    second_factor.enabled?
  end

  def verify_second_factor(otp)
    return false unless second_factor_enabled?

    second_factor = second_factors.enabled.last

    second_factor.verify(otp)
  end

  def revoke_tokens(except: nil)
    s = if except.present?
          tokens.where.not(id: except)
        else
          tokens
        end

    s.destroy_all
  end

  # Our async destroy logic needs to be a bit different to prevent accounts
  # from going under the minimum admin threshold
  def destroy_async
    if has_role?(:admin) && account.admins.count <= MINIMUM_ADMIN_COUNT
      errors.add :account, :admins_required, message: "account must have at least #{MINIMUM_ADMIN_COUNT} admin user"

      return false
    end

    super
  end

  private

  def set_user_role!
    grant! :user
  end

  def enforce_admin_minimum_on_account!
    return if !has_role?(:admin) && !was_role?(:admin)

    admin_count = account.admins.count

    # Count is not accounting for the current role changes
    if !has_role?(:admin) && was_role?(:admin)
      admin_count -= 1
    end

    if admin_count < MINIMUM_ADMIN_COUNT
      errors.add :account, :admins_required, message: "account must have at least #{MINIMUM_ADMIN_COUNT} admin user"

      throw :abort
    end
  end
end
