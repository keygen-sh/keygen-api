module Roleable
  extend ActiveSupport::Concern

  def grant(role)
    roles.create name: role
  rescue ActiveRecord::RecordNotSaved
    roles.new name: role
  end

  def revoke(role)
    roles.find_by(name: role).destroy
  end

  def role?(role)
    roles.exists? name: role
  end
end
