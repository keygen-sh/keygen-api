# frozen_string_literal: true

class TokenPermission < ApplicationRecord
  belongs_to :token
  belongs_to :permission

  # FIXME(ezekg) should have an account_id foreign key
  delegate :account, :account_id,
    allow_nil: true,
    to: :token

  def self.actions
    joins(:permission).reorder('permissions.action ASC')
                      .pluck('permissions.action')
  end
end
