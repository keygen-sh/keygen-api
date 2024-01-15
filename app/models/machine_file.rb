# frozen_string_literal: true

class MachineFile
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :account_id,     :uuid
  attribute :environment_id, :uuid
  attribute :license_id,     :uuid
  attribute :machine_id,     :uuid
  attribute :certificate,    :string
  attribute :issued_at,      :datetime
  attribute :expires_at,     :datetime
  attribute :ttl,            :integer
  attribute :includes,       :array,    default: []

  validates :account_id,  presence: true
  validates :license_id,  presence: true
  validates :machine_id,  presence: true
  validates :certificate, presence: true
  validates :issued_at,   presence: true

  validates_format_of :certificate,
    with: /\A-----BEGIN MACHINE FILE-----\n/,
    message: 'invalid prefix'
  validates_format_of :certificate,
    with: /-----END MACHINE FILE-----\n\z/,
    message: 'invalid suffix'

  validates_numericality_of :ttl,
    greater_than_or_equal_to: 1.hour,
    less_than_or_equal_to: 1.year,
    allow_nil: true

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

  def machine = @machine ||= Machine.find_by(id: machine_id, account_id:)
  def machine=(machine)
    self.machine_id = machine&.id
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
