# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :context, :resource

  def initialize(context, resource)
    @context  = context
    @resource = resource
  end

  def index?
    assert_account_scoped!

    false
  end

  def show?
    assert_account_scoped!

    false
  end

  def create?
    assert_account_scoped!

    false
  end

  def new?
    create?
  end

  def update?
    assert_account_scoped!

    false
  end

  def edit?
    update?
  end

  def destroy?
    assert_account_scoped!

    false
  end

  def search?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end

  protected

  def scope
    Pundit.policy_scope! bearer, resource.class
  end

  def account
    context.account
  end

  def bearer
    context.bearer
  end

  def token
    context.token
  end

  def assert_account_scoped!
    raise NotAuthorizedError, reason: 'account mismatch for bearer' unless
      bearer.nil? || bearer.account_id == account.id

    case
    when resource.respond_to?(:all?)
      raise NotAuthorizedError, reason: 'account mismatch for resources' unless
        resource.all? { |r| r.account_id == account.id }
    when resource.respond_to?(:account_id)
      raise NotAuthorizedError, reason: 'account mismatch for resource' unless
        resource.account_id == account.id
    else
      # NOTE(ezekg) We likely passed in the model class directly, e.g. `authorize(RequestLog)`,
      #             so we can assume the action is scoping itself correctly.
    end
  end

  class Scope
    attr_reader :context, :scope

    def initialize(context, scope)
      @context = context
      @scope   = scope
    end

    def resolve
      case
      when bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
        scope
      when scope.respond_to?(:bearer) && bearer.has_role?(:product, :user, :license)
        scope.bearer bearer.id
      when scope.respond_to?(:product) && bearer.has_role?(:product)
        scope.product bearer.id
      when scope.respond_to?(:user) && bearer.has_role?(:user)
        scope.user bearer.id
      when scope.respond_to?(:license) && bearer.has_role?(:license)
        scope.license bearer.id
      else
        scope.none
      end
    rescue NoMethodError
      scope.none
    end

    private

    def account
      context.account
    end

    def bearer
      context.bearer
    end

    def token
      context.token
    end
  end
end
