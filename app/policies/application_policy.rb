# frozen_string_literal: true

class ApplicationPolicy
  include ActionPolicy::Policy::Core
  include ActionPolicy::Policy::Authorization
  include ActionPolicy::Policy::PreCheck
  include ActionPolicy::Policy::Scoping
  include ActionPolicy::Policy::Cache
  include ActionPolicy::Policy::Reasons

  pre_check :verify_account!
  pre_check :verify_authenticated!

  authorize :account
  authorize :environment, allow_nil: true, optional: true
  authorize :bearer,      allow_nil: true
  authorize :token,       allow_nil: true, optional: true

  scope_matcher :active_record_relation, ActiveRecord::Relation
  scope_for :active_record_relation do |relation|
    relation = relation.for_environment(environment) if
      relation.respond_to?(:for_environment)

    case bearer
    in role: Role(:admin | :developer | :read_only | :sales_agent | :support_agent)
      relation.all
    in role: Role(:environment | :product | :user | :license) if relation.respond_to?(:accessible_by)
      relation.accessible_by(bearer)
    in role: Role(:environment) if relation.respond_to?(:for_environment)
      relation.for_environment(bearer.id)
    in role: Role(:product) if relation.respond_to?(:for_product)
      relation.for_product(bearer.id)
    in role: Role(:user) if relation.respond_to?(:for_user)
      relation.for_user(bearer.id)
    in role: Role(:license) if relation.respond_to?(:for_license)
      relation.for_license(bearer.id)
    else
      relation.none
    end
  end

  def skip_verify_permissions! = @skip_verify_permissions = true
  def skip_verify_permissions? = !!@skip_verify_permissions

  private

  def whatami = bearer.role.name.underscore.humanize(capitalize: false)

  def record_id = record.respond_to?(:id) ? record.id : nil
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

  # Short and easier to remember/use alias. Also makes record arg required,
  # ensures we always use :inline_reasons.
  def allow?(rule, record, *, **) = allowed_to?(:"#{rule}?", record, *, inline_reasons: true, **)

  # Overriding policy_for() to add custom options/keywords, such as the option to skip
  # permissions checks for nested policy checks via :skip_verify_permissions.
  def policy_for(skip_verify_permissions: false, **)
    policy = super(**)

    policy&.skip_verify_permissions! if
      skip_verify_permissions

    policy
  end

  ##
  # verify_account verifies the current account matches for all records.
  def verify_account!
    return if
      account.nil?

    deny! "#{whatami} account does not match current account" if
      bearer.present? && bearer.account_id != account.id

    deny! 'token account does not match current account' if
      token.present? && token.account_id != account.id

    authorization_context.except(:account, :bearer, :token)
                         .each do |context, model|
      next unless
        model.respond_to?(:account_id)

      deny! "#{context.to_s.underscore.humanize(capitalize: false)} account does not match current account" if
        model.account_id != account.id
    end

    case record
    in [{ account_id: _ }, *] => r if r.any? { it.account_id != account.id }
      deny! "a record's account does not match current account"
    in { account_id: } if account_id != account.id
      deny! 'record account does not match current account'
    else
    end
  end

  def verify_authenticated!
    deny! 'authentication is required' if unauthenticated?
  end

  ##
  # verify_environment verifies the current environment matches for all records.
  #
  # When :strict is false, the current environment is shared with the global (nil)
  # environment, and records from the nil environment are allowed to bleed into
  # the current environment-scoped records, given the current environment is a
  # shared environment. Generally, this is only used for reads (plus e.g.
  # validations and downloads).
  def verify_environment!(strict: true)
    # For isolated environments, the bearer can only be from the current isolated
    # environment. For shared environments, the bearer can be from the current
    # environment or from the global environment. For the global environment,
    # the bearer must be from the global environment.
    deny! "#{whatami} environment is not compatible with the current environment" unless
      bearer.nil? || begin
        bearer_environment_id = case bearer
                                in Environment(id: environment_id)
                                  environment_id
                                in environment_id:
                                  environment_id
                                end

        case
        when environment.nil?
          bearer_environment_id.nil?
        when environment.isolated?
          bearer_environment_id == environment.id || (
            # NB(ezekg) allow global admins to escape environment isolation
            bearer in role: Role(:admin), environment_id: nil
          )
        when environment.shared?
          bearer_environment_id == environment.id || bearer_environment_id.nil?
        end
      end

    # ^^^ ditto for the token.
    deny! 'token environment is not compatible with the current environment' unless
      token.nil? || (
        case
        when environment.nil?
          token.environment_id.nil?
        when environment.isolated?
          token.environment_id == environment.id
        when environment.shared?
          token.environment_id == environment.id || token.environment_id.nil?
        end
      )

    # ^^^ ditto for the remaining authz contexts.
    authorization_context.except(:account, :environment, :bearer, :token)
                         .each do |context, model|
      next unless
        model.respond_to?(:environment_id)

      deny! "#{context.to_s.underscore.humanize(capitalize: false)} environment is not compatible with the current environment" unless
        case
        when environment.nil?
          model.environment_id.nil?
        when environment.isolated?
          model.environment_id == environment.id
        when environment.shared?
          model.environment_id == environment.id || model.environment_id.nil?
        end
    end

    # bail early if there is no record to avoid environment mismatch false-positives
    return if
      record.nil?

    # ^^^ ditto for the record, except we're potentially allowed to access records
    # from other environments if strict-mode is disabled.
    case record
    in [{ environment_id: _ }, *] => records
      deny! "a record's environment is not compatible with the current environment" unless
        records.all? { |record|
          case
          when environment.nil?
            !strict || record.environment_id.nil?
          when environment.isolated?
            record.environment_id == environment.id
          when environment.shared?
            record.environment_id == environment.id || !strict && record.environment_id.nil?
          end
        }
    in { environment_id: }
      deny! 'record environment is not compatible with the current environment' unless
        case
        when environment.nil?
          !strict || record.environment_id.nil?
        when environment.isolated?
          environment_id == environment.id
        when environment.shared?
          environment_id == environment.id || !strict && environment_id.nil?
        end
    in [*] => records
      deny! 'records are not compatible with the current environment' unless
        !strict || environment.nil?
    else
      deny! 'record is not compatible with the current environment' unless
        !strict || environment.nil?
    end
  end

  def verify_permissions!(*actions)
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
  end

  def verify_license_for_release!(license:, release:)
    deny! 'license is suspended' if
      license.suspended?

    deny! 'license is banned' if
      license.banned?

    deny! 'license is expired' if
      license.revoke_access? && license.expired?

    deny! 'license expiry falls outside of access window' if
      license.expires? && !license.allow_access? && (release.backdated_to.presence || release.created_at) > license.expiry

    deny! 'license is missing entitlements' unless
      license.entitled?(release.entitlements)
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
