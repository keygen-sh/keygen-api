class Token < ApplicationRecord
  TOKEN_DURATION = 2.weeks

  include Tokenable

  acts_as_paranoid

  belongs_to :account
  belongs_to :bearer, polymorphic: true

  attr_reader :raw

  validates :account, presence: true
  validates :bearer, presence: true

  scope :bearer, -> (id) { where bearer: id }

  def generate!
    @raw, enc = generate_encrypted_token :digest do |token|
      "#{account.id}.#{id}.#{token}"
    end

    self.digest = enc
    self.expiry = Time.current + TOKEN_DURATION
    save

    raw
  end
  alias_method :regenerate!, :generate!

  def expired?
    expiry.nil? || expiry < Time.current
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
#  deleted_at  :datetime
#  id          :uuid             not null, primary key
#  bearer_id   :uuid
#  account_id  :uuid
#
# Indexes
#
#  index_tokens_on_account_id  (account_id)
#  index_tokens_on_bearer_id   (bearer_id)
#  index_tokens_on_created_at  (created_at)
#  index_tokens_on_deleted_at  (deleted_at)
#  index_tokens_on_id          (id)
#
