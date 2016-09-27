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
      scope
    end
  end
end
