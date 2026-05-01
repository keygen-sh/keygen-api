# frozen_string_literal: true

class Session < ApplicationRecord
  MAX_AGE = 2.weeks

  include AsyncUpdatable, AsyncDestroyable
  include Denormalizable
  include Environmental
  include Accountable

  belongs_to :token, optional: true
  belongs_to :bearer,
    polymorphic: true
  belongs_to :parent,
    class_name: Session.name,
    optional: true

  has_environment skip_verify_associations: %i[parent], default: -> {
    case bearer
    in Environment(id: environment_id)
      environment_id
    in environment_id:
      environment_id
    else
      nil
    end
  }
  has_account default: -> { bearer&.account_id }, inverse_of: :sessions

  has_many :children,
    class_name: Session.name,
    foreign_key: :parent_id,
    dependent: :destroy_async,
    inverse_of: :parent

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

  # assert that bearer matches the parent's bearer
  validate on: %i[create update] do
    next unless
      parent_id_changed? || bearer_type_changed? || bearer_id_changed?

    unless parent.nil? || bearer_type == parent.bearer_type && bearer_id == parent.bearer_id
      errors.add :bearer, :not_allowed, message: 'bearer must match parent bearer'
    end
  end

  # assert that a child session cannot outlive its parent
  validate on: %i[create update] do
    next unless
      parent.present? && parent.expiry? # anything goes if parent doesn't expire

    if expiry.nil? || parent.expiry < expiry
      errors.add :expiry, :invalid, message: 'cannot outlive parent session'
    end
  end

  def expires_in?(dt) = expiry - dt < Time.current
  def expired?        = expiry < Time.current || created_at < MAX_AGE.ago
  def expires?        = expiry?
end
