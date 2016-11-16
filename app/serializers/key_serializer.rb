class KeySerializer < BaseSerializer
  type :keys

  attributes [
    :id,
    :key,
    :created,
    :updated
  ]

  belongs_to :account
  belongs_to :policy
end

# == Schema Information
#
# Table name: keys
#
#  id         :integer          not null, primary key
#  key        :string
#  policy_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer
#  deleted_at :datetime
#
# Indexes
#
#  index_keys_on_account_id  (account_id)
#  index_keys_on_deleted_at  (deleted_at)
#  index_keys_on_policy_id   (policy_id)
#
