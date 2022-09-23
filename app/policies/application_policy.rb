# frozen_string_literal: true

class ApplicationPolicy
  include ActionPolicy::Policy::Core
  include ActionPolicy::Policy::Authorization
  include ActionPolicy::Policy::PreCheck
  include ActionPolicy::Policy::Scoping
  include ActionPolicy::Policy::Cache
  include ActionPolicy::Policy::Reasons
  prepend ActionPolicy::Policy::Rails::Instrumentation

  pre_check :verify_account_scoped!
  pre_check :verify_authenticated!

  authorize :account
  authorize :bearer, allow_nil: true
  authorize :token,  allow_nil: true

  scope_matcher :active_record_relation, ActiveRecord::Relation
  scope_for :active_record_relation do |relation|
    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' | 'sales_agent' | 'support_agent' }
      relation.all
    in role: { name: 'product' | 'user' | 'license' } if relation.respond_to?(:accessible_by)
      relation.accessible_by(bearer)
    in role: { name: 'product' } if relation.respond_to?(:for_product)
      relation.for_product(bearer.id)
    in role: { name: 'user' } if relation.respond_to?(:for_user)
      relation.for_user(bearer.id)
    in role: { name: 'license' } if relation.respond_to?(:for_license)
      relation.for_license(bearer.id)
    else
      relation.none
    end
  end

  def skip_verify_permissions! = @skip_verify_permissions = true
  def skip_verify_permissions? = !!@skip_verify_permissions

  private

  def whatami = bearer.role.name.humanize(capitalize: false)

  def record_ids
    case
    when record.respond_to?(:ids)
      record.ids
    when record.respond_to?(:collect)
      record.collect(&:id)
    else
      []
    end
  end

  def authenticated?   = bearer.present?
  def unauthenticated? = !authenticated?

  # Short and easier to remember/use alias. Also makes record arg required.
  def allow?(rule, record, *args, **kwargs) = allowed_to?(:"#{rule}?", record, *args, **kwargs)

  # Overriding policy_for() to add custom options/keywords, such as the option to skip
  # permissions checks for nested policy checks via :skip_verify_permissions.
  def policy_for(skip_verify_permissions: false, **kwargs)
    policy = super(**kwargs)

    policy&.skip_verify_permissions! if
      skip_verify_permissions

    policy
  end

  def verify_account_scoped!
    deny! "#{whatami} account does not match account context" if
      bearer.present? && bearer.account_id != account.id

    authorization_context.except(:account, :bearer, :token)
                         .each do |context, model|
      next unless
        model.respond_to?(:account_id)

      deny! "#{whatami} account does not match #{context.to_s.humanize.downcase} context" if
        bearer.present? && bearer.account_id != model.account_id
    end

    case record
    in [{ account_id: _ }, *] => r if r.any? { _1.account_id != account.id }
      deny! "a record's account does not match account context"
    in { account_id: } if account_id != account.id
      deny! 'record account does not match account context'
    else
    end
  end

  def verify_authenticated!
    deny! 'authentication is required' if unauthenticated?
  end

  def verify_permissions!(*actions)
    catch :policy_fulfilled do
      return if
        skip_verify_permissions?

      return if
        bearer.nil?

      deny! "#{whatami} lacks permission to perform action" unless
        bearer.can?(actions)

      return if
        token.nil?

      deny! 'token is expired' if
        token.expired?

      deny! 'token lacks permission to perform action' unless
        token.can?(actions)

      return
    end

    throw :policy_fulfilled if ENV.key?('KEYGEN_ENABLE_PERMISSIONS')
  end

  def verify_license_for_release!(license:, release:)
    deny! 'license is suspended' if
      license.suspended?

    deny! 'license is banned' if
      license.banned?

    deny! 'license is expired' if
      license.revoke_access? && license.expired?

    deny! 'license expiry falls outside of access window' if
      license.expires? && !license.allow_access? &&
      release.created_at > license.expiry

    deny! 'license is missing entitlements' if
      release.entitlements.any? &&
      (release.entitlements & license.entitlements).size != release.entitlements.size
  end

  def verify_licenses_for_release!(licenses:, release:)
    results = []

    licenses.each do |license|
      # We're catching :policy_fulfilled so that we can verify all licenses,
      # but still bubble up the deny! reason in case of a failure. In case
      # of a valid license, this will return early.
      catch :policy_fulfilled do
        verify_license_for_release!(license:, release:)

        return
      end

      results << result.value
    end

    # Return early if any results are truthy.
    return if
      results.any?

    # Otherwise, rethrow the :policy_fulfilled symbol, which will be handled
    # internally by Action Policy and bubble up the last result reason.
    throw :policy_fulfilled
  end
end
