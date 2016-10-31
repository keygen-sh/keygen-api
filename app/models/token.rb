class Token < ApplicationRecord
  include Tokenable

  belongs_to :account
  belongs_to :bearer, polymorphic: true

  attr_reader :raw

  def generate!
    @raw, enc = generate_encrypted_token :digest do |token|
      "#{account.hashid}.#{hashid}.#{token}"
    end

    self.digest = enc
    save

    raw
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
#
# Indexes
#
#  index_tokens_on_account_id                 (account_id)
#  index_tokens_on_bearer_id_and_bearer_type  (bearer_id,bearer_type)
#
