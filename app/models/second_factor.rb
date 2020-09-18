# frozen_string_literal: true

class SecondFactor < ApplicationRecord
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

  private

  def generate_secret!
    self.secret = ROTP::Base32.random
  end

  def generate_uri!
    totp = ROTP::TOTP.new(secret, issuer: 'Keygen')

    @uri = totp.provisioning_uri(user.email)
  end
end
