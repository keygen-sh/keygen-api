class TokenPolicy < ApplicationPolicy

  def revoke?
    bearer == resource.bearer
  end
end
