# frozen_string_literal: true

class SecondFactor < ApplicationRecord
  SECOND_FACTOR_ISSUER = 'Keygen'
  SECOND_FACTOR_IMAGE = 'https://keygen.sh/authy-icon.png'

  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :user

  before_create :generate_secret!

  validates :account, presence: { message: 'must exist' }
  validates :user, presence: { message: 'must exist' }

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  scope :product, -> (id) { joins(user: { licenses: :policy }).where policies: { product_id: id } }
  scope :user, -> (id) { where user: id }

  def uri
    return nil if enabled?

    totp = ROTP::TOTP.new(secret, issuer: SECOND_FACTOR_ISSUER, image: SECOND_FACTOR_IMAGE)

    totp.provisioning_uri(user.email)
  end

  def verify(otp)
    totp = ROTP::TOTP.new(secret, issuer: SECOND_FACTOR_ISSUER)
    ts = totp.verify(otp.to_s, after: last_verified_at.to_i)

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
