class Token < ApplicationRecord
  TOKEN_DURATION = 2.weeks

  include Tokenable
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :bearer, polymorphic: true

  attr_reader :raw

  validates :account, presence: true
  validates :bearer, presence: true

  scope :bearer, -> (id) { where bearer: id }

  def generate!(expiry: TOKEN_DURATION, version: Tokenable::ALGO_VERSION)
    @raw, enc = generate_hashed_token :digest, version: version do |token|
      case version
      when "v1"
        "#{account.id.delete "-"}.#{id.delete "-"}.#{token}"
      when "v2"
        "#{kind[0..3]}-#{token}"
      end
    end

    self.digest = enc
    self.expiry = Time.current + expiry if expiry
    save

    raw
  end
  alias_method :regenerate!, :generate!

  def expired?
    return false if expiry.nil?

    expiry < Time.current
  end

  def product_token?
    bearer.role? :product
  end

  def admin_token?
    bearer.role? :admin
  end

  def user_token?
    bearer.role? :user
  end

  def kind
    case
    when product_token?
      "product-token"
    when admin_token?
      "admin-token"
    when user_token?
      "user-token"
    end
  end
end

# == Schema Information
#
# Table name: tokens
#
#  digest      :string
#  bearer_type :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  expiry      :datetime
#  id          :uuid             not null, primary key
#  bearer_id   :uuid
#  account_id  :uuid
#
# Indexes
#
#  index_tokens_on_account_id_and_created_at                 (account_id,created_at)
#  index_tokens_on_bearer_id_and_bearer_type_and_created_at  (bearer_id,bearer_type,created_at)
#  index_tokens_on_digest_and_created_at_and_account_id      (digest,created_at,account_id) UNIQUE
#  index_tokens_on_id_and_created_at_and_account_id          (id,created_at,account_id) UNIQUE
#
