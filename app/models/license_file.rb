# frozen_string_literal: true

class LicenseFile
  include ActiveModel::Model
  include ActiveModel::Attributes

  ALGORITHMS = %w[
    aes-256-gcm+ed25519
    aes-256-gcm+rsa-pss-sha256
    aes-256-gcm+rsa-sha256
    base64+ed25519
    base64+rsa-pss-sha256
    base64+rsa-sha256
  ].freeze

  attribute :account_id,     :uuid
  attribute :environment_id, :uuid
  attribute :license_id,     :uuid
  attribute :certificate,    :string
  attribute :issued_at,      :datetime
  attribute :expires_at,     :datetime
  attribute :ttl,            :integer
  attribute :includes,       :array,    default: []
  attribute :algorithm,      :string

  validates :account_id,  presence: true
  validates :license_id,  presence: true
  validates :certificate, presence: true
  validates :issued_at,   presence: true

  validates_format_of :certificate,
    with: /\A-----BEGIN LICENSE FILE-----\n/,
    message: 'invalid prefix'
  validates_format_of :certificate,
    with: /-----END LICENSE FILE-----\n\z/,
    message: 'invalid suffix'

  validates_numericality_of :ttl,
    greater_than_or_equal_to: 1.hour,
    allow_nil: true

  validates_inclusion_of :algorithm,
    in: ALGORITHMS

  def persisted? = false
  def id         = @id      ||= SecureRandom.uuid
  def product    = @product ||= license&.product
  def owner      = @owner   ||= license&.owner

  def account = @account ||= Account.find_by(id: account_id)
  def account=(account)
    self.account_id = account&.id
  end

  def license = @license ||= License.find_by(id: license_id, account_id:)
  def license=(license)
    self.license_id = license&.id
  end

  def environment
    @environment ||= unless environment_id.nil?
                       Environment.find_by(id: environment_id, account_id:)
                     end
  end
  def environment=(environment)
    self.environment_id = environment&.id
  end
end
