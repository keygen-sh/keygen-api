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

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent)
  end

  protected

  def account
    context.account
  end

  def bearer
    context.bearer
  end

  def token
    context.token
  end

  def scope
    Pundit.policy_scope! bearer, resource.class
  end

  def assert_account_scoped!
    raise Pundit::NotAuthorizedError, reason: 'account mismatch for bearer' unless
      bearer.nil? || bearer.account_id == account.id

    case
    when resource.respond_to?(:all?)
      raise Pundit::NotAuthorizedError, reason: 'account mismatch for resources' unless
        resource.all? { |r| r.account_id == account.id }
    when resource.respond_to?(:account_id)
      raise Pundit::NotAuthorizedError, reason: 'account mismatch for resource' unless
        resource.account_id == account.id
    else
      # NOTE(ezekg) We likely passed in the model class directly, e.g. `authorize(RequestLog)`,
      #             so we can assume the action is scoping itself correctly.
    end
  end

  def assert_permissions!(*actions)
    actions.flatten.each do |action|
      next if
        bearer.nil?

      raise Pundit::NotAuthorizedError, reason: 'bearer lacks permissions' unless
        bearer.permissions.exists?(action:)

      next if
        token.nil?

      raise Pundit::NotAuthorizedError, reason: 'token lacks permissions' unless
        token.permissions.exists?(action:)
    end
  end

  private

  class Scope
    attr_reader :context, :scope

    def initialize(context, scope)
      @context = context
      @scope   = scope
    end

    def resolve
      return scope.none if bearer.nil?

      case
      when bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent)
        scope
      when scope.respond_to?(:for_bearer) && bearer.has_role?(:product, :user, :license)
        scope.for_bearer(bearer.class.name, bearer.id)
      when scope.respond_to?(:for_product) && bearer.has_role?(:product)
        scope.for_product(bearer.id)
      when scope.respond_to?(:for_user) && bearer.has_role?(:user)
        scope.for_user(bearer.id)
      when scope.respond_to?(:for_license) && bearer.has_role?(:license)
        scope.for_license(bearer.id)
      else
        scope.none
      end
    rescue NoMethodError => e
      Keygen.logger.exception(e)

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
