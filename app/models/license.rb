class License < ApplicationRecord
  include Limitable
  include Tokenable
  include Pageable

  belongs_to :account
  belongs_to :user
  belongs_to :policy
  has_many :machines, dependent: :destroy
  has_one :product, through: :policy

  attr_reader :raw

  before_create :set_expiry, unless: -> { policy.nil? }
  after_create :set_key, unless: -> { key.present? || policy.nil? }

  validates :account, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }

  validate on: :create do
    errors.add :key, "cannot specify key for encrypted license" if key.present? && policy.encrypted?
  end

  validate unless: -> { policy.nil? } do
    errors.add :machines, "count has reached maximum allowed by policy" if !policy.max_machines.nil? && machines.size > policy.max_machines
  end

  validates :key, uniqueness: { case_sensitive: true }, unless: -> { key.nil? }

  scope :policy, -> (id) { where policy: id }
  scope :user, -> (id) { where user: id }
  scope :product, -> (id) { joins(:policy).where policies: { product_id: id } }

  private

  def set_key
    case
    when policy.pool?
      if item = policy.pop!
        self.key = item.key
      else
        errors.add :policy, "pool is empty"
      end
    when policy.encrypted?
      @raw, enc = generate_encrypted_token :key do |token|
        # Replace first n characters with our id so that we can do a lookup
        # on the encrypted key
        token.gsub(/\A.{#{UUID_LENGTH}}/, id.delete("-"))
             .scan(/.{#{UUID_LENGTH}}/).join "-"
      end

      self.key = enc
    else
      self.key = generate_token :key do |token|
        token.gsub(/\A.{#{UUID_LENGTH}}/, id.delete("-"))
             .scan(/.{#{UUID_LENGTH}}/).join "-"
      end
    end

    # We're raising a RecordInvalid exception so that the transaction will be
    # halted and rolled back (since our record is invalid without a key)
    raise ActiveRecord::RecordInvalid if key.nil?

    save
  end

  def set_expiry
    if policy.duration.nil?
      self.expiry = nil
    else
      self.expiry = Time.current + policy.duration
    end
  end
end

# == Schema Information
#
# Table name: licenses
#
#  id         :uuid             not null, primary key
#  key        :string
#  expiry     :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  metadata   :jsonb
#  user_id    :uuid
#  policy_id  :uuid
#  account_id :uuid
#
# Indexes
#
#  index_licenses_on_created_at_and_account_id  (created_at,account_id)
#  index_licenses_on_created_at_and_id          (created_at,id) UNIQUE
#  index_licenses_on_created_at_and_policy_id   (created_at,policy_id)
#  index_licenses_on_created_at_and_user_id     (created_at,user_id)
#
