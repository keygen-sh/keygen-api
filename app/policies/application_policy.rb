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
    in role: { name: 'product' | 'user' | 'license' } if relation.respond_to?(:for_bearer)
      relation.for_bearer(bearer.class.name, bearer.id)
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
    deny! 'bearer account does not match current account' if
      bearer.present? && bearer.account_id != account.id

    case record
    in [{ account_id: _ }, *] => r if r.any? { _1.account_id != account.id }
      deny! "a record's account does not match current account"
    in { account_id: } if account_id != account.id
      deny! 'record account does not match current account'
    else
    end
  end

  def verify_authenticated!
    deny! 'bearer is missing' if bearer.nil?
  end

  def verify_permissions!(*actions)
    return if
      bearer.nil?

    deny! 'bearer is banned' if
      (bearer.user? || bearer.license?) && bearer.banned?

    deny! 'bearer is suspended' if
      bearer.license? && bearer.suspended?

    deny! 'bearer lacks permission to perform action' unless
      bearer.can?(actions)

    return if
      token.nil?

    deny! 'token is expired' if
      token.expired?

    deny! 'token lacks permission to perform action' unless
      token.can?(actions)
  end
end
