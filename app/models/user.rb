# frozen_string_literal: true

class User < ApplicationRecord
  MINIMUM_ADMIN_COUNT = 1

  include PasswordResetable
  include Limitable
  include Pageable
  include Roleable
  include Searchable

  SEARCH_ATTRIBUTES = [:id, :email, :first_name, :last_name, :metadata, { full_name: [:first_name, :last_name] }].freeze
  SEARCH_RELATIONSHIPS = { role: %i[name] }.freeze

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  has_secure_password

  belongs_to :account
  has_many :second_factors, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_many :products, -> { select('"products".*, "products"."id", "products"."created_at"').distinct('"products"."id"').reorder(Arel.sql('"products"."created_at" ASC')) }, through: :licenses
  has_many :machines, through: :licenses
  has_many :tokens, as: :bearer, dependent: :destroy
  has_one :role, as: :resource, dependent: :destroy

  accepts_nested_attributes_for :role, update_only: true

  before_destroy :enforce_admin_minimum_on_account!
  before_update :enforce_admin_minimum_on_account!, if: -> { role.present? && role.changed? }
  before_create :set_user_role!, if: -> { role.nil? }

  before_save -> { self.email = email.downcase }

  validates :email, email: true, presence: true, length: { maximum: 255 }, uniqueness: { case_sensitive: false, scope: :account_id }
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  # FIXME(ezekg) Hack to override pg_search with more performant query
  # TODO(ezekg) Rip out pg_search
  scope :search_email, -> (term) {
    where('email ILIKE ?', "%#{term}%")
  }

  scope :search_metadata, -> (terms) {
    # FIXME(ezekg) Need to figure out a better way to do this. We need to be able
    #              to search for the original string values and type cast, since
    #              HTTP querystring parameters are strings.
    #
    #              Example we need to be able to search for:
    #
    #                { metadata: { internalId: "1624214616", otherId: 1 } }
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

  scope :metadata, -> (meta) { search_metadata meta }
  scope :roles, -> (*roles) { joins(:role).where roles: { name: roles.flatten.map { |r| r.to_s.underscore } } }
  scope :product, -> (id) { joins(licenses: [:policy]).where policies: { product_id: id } }
  scope :license, -> (id) { joins(:license).where licenses: id }
  scope :user, -> (id) { where id: id }
  scope :admins, -> { roles :admin }
  scope :active, -> (status = true) {
    sub_query = License.where('"licenses"."user_id" = "users"."id"').select(1).arel.exists

    if ActiveRecord::Type::Boolean.new.cast(status)
      where(sub_query)
    else
      where.not(sub_query)
    end
  }

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
