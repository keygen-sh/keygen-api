class UserPolicy < ApplicationPolicy

  def index?
    bearer.role? :admin or bearer.role? :product
  end

  def show?
    bearer.role? :admin or resource == bearer or resource.products.include? bearer
  end

  def create?
    (bearer.present? and (bearer.role? :admin or resource.products.include? bearer)) or !account.protected?
  end

  def update?
    bearer.role? :admin or resource == bearer or resource.products.include? bearer
  end

  def destroy?
    bearer.role? :admin
  end

  def read_tokens?
    bearer.role? :admin or resource == bearer
  end

  def update_password?
    resource == bearer
  end

  def reset_password?
    resource == bearer
  end
end
