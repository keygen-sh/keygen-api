module Roleable
  extend ActiveSupport::Concern

  included do
    def allowed_roles
      self.class::ALLOWED_ROLES
    end
  end

  def grant(name)
    self.role = Role.create name: name
  rescue ActiveRecord::RecordNotSaved
    self.role = Role.new name: name
  end

  def revoke(name)
    role.destroy if role.name == name.to_s
  end

  def role?(name)
    role.name == name.to_s
  end
end
