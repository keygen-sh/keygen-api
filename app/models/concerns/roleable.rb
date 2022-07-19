# frozen_string_literal: true

module Roleable
  extend ActiveSupport::Concern

  def grant!(name)
    if role.nil?
      self.role = Role.create(name:)
    else
      self.role.name = name
    end
  rescue ActiveRecord::RecordNotSaved
    self.role = Role.new(name:)
  end

  def revoke!(name)
    return false if
      role.nil? || name.to_s != role.name

    role.destroy
  end

  def has_role?(*names)
    return false if
      role.nil?

    names.any? { _1.to_s == role.name }
  end

  def was_role?(name)
    return false if
      role.nil? || !role.name_changed?

    name.to_s == role.name_was
  end
end
