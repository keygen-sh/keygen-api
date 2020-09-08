# frozen_string_literal: true

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

  def search?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end

  def scope
    Pundit.policy_scope! bearer, resource.class
  end

  def account
    resource.account rescue bearer.account
  end

  class Scope
    attr_reader :bearer, :scope

    def initialize(bearer, scope)
      @bearer = bearer
      @scope = scope
    end

    def resolve
      case
      when bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
        scope.all
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
  end
end