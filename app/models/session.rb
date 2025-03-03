# frozen_string_literal: true

class Session < ApplicationRecord
  MAX_AGE = 2.weeks

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

  validates :token,
    presence: { message: 'must exist' },
    scope: { by: :account_id }

  validates :bearer,
    presence: { message: 'must exist' },
    scope: { by: :account_id }

  # assert that bearer matches the token's bearer
  validate on: %i[create update] do
    next unless
      token_id_changed? || bearer_id_changed?

    unless token.nil? || bearer_type == token.bearer_type && bearer_id == token.bearer_id
      errors.add :bearer, :not_allowed, message: 'bearer must match token bearer'
    end
  end

  def expires_in?(dt) = expiry - dt < Time.current
  def expired?        = expiry < Time.current || created_at < MAX_AGE.ago
end
