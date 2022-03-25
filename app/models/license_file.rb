# frozen_string_literal: true

class LicenseFile
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :account_id,  :uuid
  attribute :license_id,  :uuid
  attribute :certificate, :string
  attribute :issued_at,   :datetime
  attribute :expires_at,  :datetime
  attribute :ttl,         :integer

  validates :account_id,  presence: true
  validates :license_id,  presence: true
  validates :certificate, presence: true
  validates :issued_at,   presence: true
  validates :ttl,         presence: true

  validates_format_of :certificate, with: /\A-----BEGIN LICENSE FILE-----\n/
  validates_format_of :certificate, with: /-----END LICENSE FILE-----\n\z/

  validates_numericality_of :ttl,
    greater_than_or_equal_to: 1.hour

  def persisted?
    false
  end

  def id
    @id ||= SecureRandom.uuid
  end
end
