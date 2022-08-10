# frozen_string_literal: true

class ApplicationPolicy
  attr_accessor :resource
  attr_reader   :context

  def initialize(context, resource)
    raise Pundit::NotAuthorizedError, 'authorization context is missing' unless
      context.is_a?(AuthorizationContext)

    # Ensure we're always dealing with an authz resource.
    resource = AuthorizationResource.new(subject: resource) unless
      resource.is_a?(AuthorizationResource)

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

  def scope      = Pundit.policy_scope!(context.bearer, resource.subject.class)
  def account    = context.account
  def account_id = account&.id
  def bearer     = context.bearer
  def bearer_id  = bearer&.id
  def token      = context.token
  def token_id   = token&.id

  def assert_account_scoped!
    raise Pundit::NotAuthorizedError, policy: self, message: 'bearer account is mismatched' unless
      bearer.nil? || bearer.account_id == account.id

    case resource.subject
    in [{ account_id: _ }, *] => s
      raise Pundit::NotAuthorizedError, policy: self, message: 'resource subject account is mismatched' unless
        s.all? { _1.account_id == account.id }
    in account_id:
      raise Pundit::NotAuthorizedError, policy: self, message: 'resource subject account is mismatched' unless
        account_id == account.id
    else
    end
  end

  def assert_authenticated!
    raise Pundit::NotAuthorizedError, policy: self, message: 'bearer is missing' if
      bearer.nil?
  end

  def assert_permissions!(*actions)
    return if
      bearer.nil?

    raise Pundit::NotAuthorizedError, policy: self, message: 'bearer is banned' if
      (bearer.user? || bearer.license?) && bearer.banned?

    raise Pundit::NotAuthorizedError, policy: self, message: 'bearer is suspended' if
      bearer.license? && bearer.suspended?

    raise Pundit::NotAuthorizedError, policy: self, message: 'bearer lacks permission to perform action' unless
      bearer.can?(actions)

    return if
      token.nil?

    raise Pundit::NotAuthorizedError, policy: self, message: 'token is expired' if
      token.expired?

    raise Pundit::NotAuthorizedError, policy: self, message: 'token lacks permission to perform action' unless
      token.can?(actions)
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
