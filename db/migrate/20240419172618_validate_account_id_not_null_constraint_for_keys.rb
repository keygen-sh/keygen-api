class ValidateAccountIdNotNullConstraintForKeys < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :keys, name: 'keys_account_id_null'

    change_column_null :keys, :account_id, false
    remove_check_constraint :keys, name: 'keys_account_id_null'
  end
end
