class License < ApplicationRecord
  include Paginatable
  include Tokenable

  belongs_to :account
  belongs_to :user
  belongs_to :policy
  has_many :machines, dependent: :destroy
  has_one :product, through: :policy

  before_validation :set_license_key, on: :create
  before_validation :set_expiry, on: :create

  validates :account, presence: { message: "must exist" }
  validates :user, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }, uniqueness: { scope: :user_id, message: "user already has a license with this policy" }

  validate do
    errors.add :machines, "count has reached maximum allowed by policy" if machines.size > policy.max_machines
  end

  validates :key, presence: true, blank: false,
    uniqueness: { case_sensitive: false }

  scope :policy, -> (id) { where policy: Policy.decode_id(id) }
  scope :user, -> (id) { where user: User.decode_id(id) }
  scope :product, -> (id) { joins(:policy).where policies: { product_id: Product.decode_id(id) } }

  def license_valid?
    # Check if license is expired
    return false unless expiry.nil? || expiry > DateTime.now
    # Check if license policy is strict, e.g. enforces reporting of machine usage
    return true unless policy.strict
    # Check if license policy allows floating and if not, should have single activation
    return true if !policy.floating && machines.count == 1
    # Assume floating, should have at least 1 activation but no more than policy allows
    return true if policy.floating && machines.count >= 1 && machines.count <= policy.max_machines
    # Otherwise, assume invalid
    return false
  end

  private

  def set_license_key
    if policy.pool?
      if item = policy.pop!
        self.key = item.key
      else
        errors.add :policy, "pool is empty"
      end
    else
      self.key = generate_token :key do |token|
        token.scan(/.{4}/).join "-"
      end
    end
  end

  def set_expiry
    if policy.duration.nil?
      self.expiry = nil
    else
      self.expiry = Time.now + policy.duration
    end
  end
end
