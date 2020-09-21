# frozen_string_literal: true

class SecondFactor < ApplicationRecord
  SECOND_FACTOR_ISSUER = 'Keygen'

  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :user

  attr_reader :uri

  before_create :generate_secret!
  before_create :generate_uri!

  validates :account, presence: { message: 'must exist' }
  validates :user, presence: { message: 'must exist' }

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  def verify(otp)
    totp = ROTP::TOTP.new(secret, issuer: SECOND_FACTOR_ISSUER)
    ts = totp.verify(otp, after: last_verified_at.to_i)

    if ts.present?
      update(last_verified_at: Time.at(ts))
    end

    ts
  end

  private

  def generate_secret!
    self.secret = ROTP::Base32.random
  end

  def generate_uri!
    totp = ROTP::TOTP.new(secret, issuer: SECOND_FACTOR_ISSUER)

    @uri = totp.provisioning_uri(user.email)
  end
end
