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

  def generate!(expiry: TOKEN_DURATION)
    @raw, enc = generate_encrypted_token :digest do |token|
      "#{account.id.delete "-"}.#{id.delete "-"}.#{token}"
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
end

# == Schema Information
#
# Table name: tokens
#
#  id          :uuid             not null, primary key
#  digest      :string
#  bearer_type :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  expiry      :datetime
#  bearer_id   :uuid
#  account_id  :uuid
#
# Indexes
#
#  index_tokens_on_account_id_and_created_at                 (account_id,created_at)
#  index_tokens_on_bearer_id_and_bearer_type_and_created_at  (bearer_id,bearer_type,created_at)
#  index_tokens_on_id_and_created_at_and_account_id          (id,created_at,account_id) UNIQUE
#
