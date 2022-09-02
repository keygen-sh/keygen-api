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

  protected

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

  private

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
    deny! 'authentication is required' if bearer.nil?
  end

  def verify_permissions!(*actions)
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
end
