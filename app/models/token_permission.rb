# frozen_string_literal: true

class TokenPermission < ApplicationRecord
  include Keygen::Exportable

  belongs_to :token
  belongs_to :permission

  def self.actions
    joins(:permission)
      .reorder('permissions.action ASC')
      .pluck('permissions.action')
  end
end
