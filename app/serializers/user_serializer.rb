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
#  id                     :integer          not null, primary key
#  name                   :string
#  email                  :string
#  password_digest        :string
#  account_id             :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  password_reset_token   :string
#  password_reset_sent_at :datetime
#  deleted_at             :datetime
#  metadata               :jsonb
#
# Indexes
#
#  index_users_on_account_id_and_id                    (account_id,id)
#  index_users_on_deleted_at                           (deleted_at)
#  index_users_on_email_and_account_id                 (email,account_id)
#  index_users_on_password_reset_token_and_account_id  (password_reset_token,account_id)
#
