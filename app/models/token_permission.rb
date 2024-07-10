# frozen_string_literal: true

class TokenPermission < ApplicationRecord
  include Keygen::Exportable

  belongs_to :token
  belongs_to :permission

  # map permission primary keys between installs
  exports -> attrs { attrs.merge(permission_action: PERMISSIONS_BY_ID[attrs.delete(:permission_id)].action) }
  imports -> attrs { attrs.merge(permission_id: PERMISSIONS_BY_ACTION[attrs.delete(:permission_action)].id) }

  def self.actions
    joins(:permission).reorder('permissions.action ASC')
                      .pluck('permissions.action')
  end
end
