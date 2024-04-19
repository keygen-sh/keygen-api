class ValidateAccountIdNotNullConstraintForUsers < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :users, name: 'users_account_id_null'

    change_column_null :users, :account_id, false
    remove_check_constraint :users, name: 'users_account_id_null'
  end
end
