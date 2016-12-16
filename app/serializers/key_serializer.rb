class KeySerializer < BaseSerializer
  type :keys

  attributes :id,
             :key,
             :created,
             :updated
end

# == Schema Information
#
# Table name: keys
#
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  id         :uuid             not null, primary key
#  policy_id  :uuid
#  account_id :uuid
#
# Indexes
#
#  index_keys_on_account_id  (account_id)
#  index_keys_on_created_at  (created_at)
#  index_keys_on_deleted_at  (deleted_at)
#  index_keys_on_id          (id)
#  index_keys_on_policy_id   (policy_id)
#
