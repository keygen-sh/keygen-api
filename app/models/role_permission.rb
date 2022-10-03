# frozen_string_literal: true

class RolePermission < ApplicationRecord
  belongs_to :role
  belongs_to :permission

  def self.actions
    joins(:permission)
      .reorder('permissions.action ASC')
      .pluck('permissions.action')
  end
end
