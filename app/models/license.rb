class License < ApplicationRecord
  LICENSE_KEY_BREAK_SIZE = Hashid::Rails.configuration.length.freeze

  include Paginatable
  include Limitable
  include Tokenable

  acts_as_paranoid

  belongs_to :account
  belongs_to :user
  belongs_to :policy
  has_many :machines, dependent: :destroy
  has_one :product, through: :policy

  attr_reader :raw

  before_create :set_expiry, unless: -> { policy.nil? }
  after_create :set_key, unless: -> { policy.nil? }

  validates :account, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }

  validate unless: -> { policy.nil? } do
    errors.add :machines, "count has reached maximum allowed by policy" if !policy.max_machines.nil? && machines.size > policy.max_machines
  end

  validates :key, uniqueness: { case_sensitive: true }, unless: -> { key.nil? }

  scope :policy, -> (id) { where policy: Policy.decode_id(id) }
  scope :user, -> (id) { where user: User.decode_id(id) }
  scope :product, -> (id) { joins(:policy).where policies: { product_id: Product.decode_id(id) } }

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
        # Replace first n characters with our hashid so that we can do a lookup
        # on the encrypted key
        token.gsub(/\A.{#{LICENSE_KEY_BREAK_SIZE}}/, hashid)
             .scan(/.{#{LICENSE_KEY_BREAK_SIZE}}/).join "-"
      end

      self.key = enc
    else
      self.key = generate_token :key do |token|
        token.scan(/.{#{LICENSE_KEY_BREAK_SIZE}}/).join "-"
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
#  id         :integer          not null, primary key
#  key        :string
#  expiry     :datetime
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  policy_id  :integer
#  account_id :integer
#  deleted_at :datetime
#  metadata   :jsonb
#
# Indexes
#
#  index_licenses_on_account_id_and_id         (account_id,id)
#  index_licenses_on_deleted_at                (deleted_at)
#  index_licenses_on_key_and_account_id        (key,account_id)
#  index_licenses_on_policy_id_and_account_id  (policy_id,account_id)
#  index_licenses_on_user_id_and_account_id    (user_id,account_id)
#
