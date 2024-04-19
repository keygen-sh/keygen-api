class ValidateAccountIdNotNullConstraintForBillings < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :billings, name: 'billings_account_id_null'

    change_column_null :billings, :account_id, false
    remove_check_constraint :billings, name: 'billings_account_id_null'
  end
end
