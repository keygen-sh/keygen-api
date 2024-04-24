class ChangeAccountIdNotNullForUsers < ActiveRecord::Migration[7.1]
  verbose!

  def up
    change_column_null :users, :account_id, false
    remove_check_constraint :users, name: 'users_account_id_not_null'
  end
end
