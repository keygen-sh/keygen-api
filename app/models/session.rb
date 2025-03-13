# frozen_string_literal: true

class Session < ApplicationRecord
  MAX_AGE = 2.weeks

  include Denormalizable
  include Environmental
  include Accountable

  belongs_to :token, optional: true
  belongs_to :bearer,
    polymorphic: true

  has_environment default: -> { bearer&.environment_id }
  has_account default: -> { bearer&.account_id }, inverse_of: :sessions

  denormalizes :bearer_type, :bearer_id,
    from: :token

  validates :token,
    presence: { message: 'must exist' },
    scope: { by: :account_id },
    unless: -> {
      token_id_before_type_cast.nil?
    }

  validates :bearer,
    presence: { message: 'must exist' },
    scope: { by: :account_id }

  validates :ip, presence: true

  # assert that bearer matches the token's bearer
  validate on: %i[create update] do
    next unless
      token_id_changed? || bearer_type_changed? || bearer_id_changed?

    unless token.nil? || bearer_type == token.bearer_type && bearer_id == token.bearer_id
      errors.add :bearer, :not_allowed, message: 'bearer must match token bearer'
    end
  end

  def expires_in?(dt) = expiry - dt < Time.current
  def expired?        = expiry < Time.current || created_at < MAX_AGE.ago
end
