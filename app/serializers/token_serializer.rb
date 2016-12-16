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
