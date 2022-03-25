class MachineFile
  include ActiveModel::Model

  attr_accessor :account_id,
                :license_id,
                :machine_id,
                :certificate,
                :issued_at,
                :expires_at,
                :ttl


  validates :account_id,  presence: true
  validates :license_id,  presence: true
  validates :machine_id,  presence: true
  validates :certificate, presence: true
  validates :issued_at,   presence: true
  validates :ttl,         presence: true

  validates_format_of :certificate, with: /\A-----BEGIN MACHINE FILE-----\n/
  validates_format_of :certificate, with: /-----END MACHINE FILE-----\n\z/

  validates_numericality_of :ttl,
    greater_than_or_equal_to: 1.hour

  def persisted?
    false
  end

  def id
    @id ||= SecureRandom.uuid
  end
end
