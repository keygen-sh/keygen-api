# frozen_string_literal: true

class Session < ApplicationRecord
  include Denormalizable
  include Environmental
  include Accountable

  belongs_to :token
  belongs_to :bearer,
    polymorphic: true

  has_environment default: -> { token&.environment_id }
  has_account default: -> { token&.account_id }, inverse_of: :sessions

  denormalizes :bearer_type, :bearer_id,
    from: :token

  def expired? = expiry < Time.current
end
