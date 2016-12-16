class UserSerializer < BaseSerializer
  type :users

  attributes :id,
             :role,
             :name,
             :email,
             :metadata,
             :created,
             :updated

  def role
    object.role.name
  end
end

# == Schema Information
#
# Table name: users
#
#  name                   :string
#  email                  :string
#  password_digest        :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  password_reset_token   :string
#  password_reset_sent_at :datetime
#  deleted_at             :datetime
#  metadata               :jsonb
#  id                     :uuid             not null, primary key
#  account_id             :uuid
#
# Indexes
#
#  index_users_on_account_id  (account_id)
#  index_users_on_created_at  (created_at)
#  index_users_on_deleted_at  (deleted_at)
#  index_users_on_id          (id)
#
