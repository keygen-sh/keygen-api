class Token < ApplicationRecord
  TOKEN_DURATION = 2.weeks

  include Tokenable

  acts_as_paranoid

  belongs_to :account
  belongs_to :bearer, polymorphic: true

  attr_reader :raw

  validates :account, presence: true
  validates :bearer, presence: true

  def generate!
    @raw, enc = generate_encrypted_token :digest do |token|
      "#{account.hashid}.#{hashid}.#{token}"
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
#  id          :integer          not null, primary key
#  digest      :string
#  bearer_id   :integer
#  bearer_type :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer
#  expiry      :datetime
#  deleted_at  :datetime
#
# Indexes
#
#  index_tokens_on_account_id_and_id                         (account_id,id)
#  index_tokens_on_bearer_id_and_bearer_type_and_account_id  (bearer_id,bearer_type,account_id)
#  index_tokens_on_deleted_at                                (deleted_at)
#
