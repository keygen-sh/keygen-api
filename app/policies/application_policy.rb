class ApplicationPolicy
  attr_reader :bearer, :resource

  def initialize(bearer, resource)
    @bearer = bearer
    @resource = resource
  end

  def index?
    false
  end

  def show?
    scope.where(id: resource.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope! bearer, resource.class
  end

  def account
    resource.account || bearer.account
  end

  class Scope
    attr_reader :bearer, :scope

    def initialize(bearer, scope)
      @bearer = bearer
      @scope = scope
    end

    def resolve
      case
      when bearer.role?(:admin)
        scope.all
      when scope.respond_to?(:bearer) && (bearer.role?(:product) || bearer.role?(:user) || bearer.role?(:license))
        scope.bearer bearer.id
      when scope.respond_to?(:product) && bearer.role?(:product)
        scope.product bearer.id
      when scope.respond_to?(:user) && bearer.role?(:user)
        scope.user bearer.id
      when scope.respond_to?(:license) && bearer.role?(:license)
        scope.license bearer.id
      else
        scope.none
      end
    rescue NoMethodError
      scope.none
    end
  end
end
