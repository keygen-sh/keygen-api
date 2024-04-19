class AddAccountIdNotNullConstraintForUsers < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :users, 'account_id IS NOT NULL', name: 'users_account_id_null', validate: false
  end
end
