class TokenSerializer < BaseSerializer
  type :tokens

  attribute :token, unless: -> { token.nil? }
  attributes :expiry,
             :created,
             :updated

  def token
    object.raw
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
