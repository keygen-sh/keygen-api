# frozen_string_literal: true

class RolePermission < ApplicationRecord
  include Keygen::Exportable

  belongs_to :role
  belongs_to :permission

  # map permission primary keys between installs
  exports -> attrs { attrs.merge(permission_action: Permission.lookup_action_by_id(attrs.delete(:permission_id))) }
  imports -> attrs { attrs.merge(permission_id: Permission.lookup_id_by_action(attrs.delete(:permission_action))) }

  def self.actions
    joins(:permission).reorder('permissions.action ASC')
                      .pluck('permissions.action')
  end
end
