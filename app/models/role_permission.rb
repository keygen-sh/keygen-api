# frozen_string_literal: true

class RolePermission < ApplicationRecord
  include Keygen::PortableClass

  belongs_to :role
  belongs_to :permission

  # FIXME(ezekg) should have an account_id foreign key
  delegate :account, :account_id,
    allow_nil: true,
    to: :role

  # map permission primary keys between installs
  exports -> attrs { attrs.merge(permission_action: Permission.lookup_action_by_id(attrs.delete(:permission_id))) }
  imports -> attrs { attrs.merge(permission_id: Permission.lookup_id_by_action(attrs.delete(:permission_action))) }

  def self.actions
    joins(:permission).reorder('permissions.action ASC')
                      .pluck('permissions.action')
  end
end
