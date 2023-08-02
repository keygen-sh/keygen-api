# frozen_string_literal: true

class SecondFactor < ApplicationRecord
  SECOND_FACTOR_ISSUER = 'Keygen'
  SECOND_FACTOR_IMAGE  = 'https://keygen.sh/images/logomark.png'
  SECOND_FACTOR_DRIFT  = 10

  include Environmental
  include Limitable
  include Orderable
  include Pageable

  encrypts :secret

  belongs_to :account
  belongs_to :user

  has_environment default: -> { user&.environment_id }

  before_create :generate_secret!

  validates :user,
    scope: { by: :account_id }

  scope :enabled,  -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  scope :for_product, -> id { joins(user: { licenses: :policy }).where(policies: { product_id: id }) }
  scope :for_user,    -> id { joins(:user).where(user: { id: }) }

  def uri
    return nil if enabled?

    totp = ROTP::TOTP.new(secret, issuer: SECOND_FACTOR_ISSUER, image: SECOND_FACTOR_IMAGE)

    totp.provisioning_uri(user.email)
  end

  def verify(otp)
    totp = ROTP::TOTP.new(secret, issuer: SECOND_FACTOR_ISSUER)
    ts   = totp.verify(otp.to_s, drift_behind: SECOND_FACTOR_DRIFT, after: last_verified_at.to_i)

    if ts.present?
      update(last_verified_at: Time.at(ts))
    end

    ts
  end

  private

  def generate_secret!
    self.secret = ROTP::Base32.random
  end
end
