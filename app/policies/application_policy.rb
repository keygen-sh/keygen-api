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

  class Scope
    attr_reader :bearer, :scope

    def initialize(bearer, scope)
      @bearer = bearer
      @scope = scope
    end

    def resolve
      case
      when @bearer.has_role?(:admin)
        scope.all
      when @bearer.has_role?(:user)
        scope
      when @bearer.has_role?(:product)
        scope.product @bearer.hashid
      end
    # rescue
    #   scope
    end
  end
end
