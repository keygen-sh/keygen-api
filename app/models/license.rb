class License < ApplicationRecord
  include Paginatable
  include Tokenable

  belongs_to :account
  belongs_to :user
  belongs_to :policy
  has_many :machines, dependent: :destroy
  has_one :product, through: :policy

  before_validation :set_license_key, on: :create, unless: -> { policy.nil? }
  before_validation :set_expiry, on: :create, unless: -> { policy.nil? }

  validates :account, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }

  validate unless: -> { policy.nil? } do
    errors.add :machines, "count has reached maximum allowed by policy" if machines.size > policy.max_machines
  end

  validates :key, presence: true, blank: false, uniqueness: { case_sensitive: false }

  scope :policy, -> (id) { where policy: Policy.decode_id(id) }
  scope :user, -> (id) { where user: User.decode_id(id) }
  scope :product, -> (id) { joins(:policy).where policies: { product_id: Product.decode_id(id) } }

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
      self.expiry = Time.current + policy.duration
    end
  end
end
