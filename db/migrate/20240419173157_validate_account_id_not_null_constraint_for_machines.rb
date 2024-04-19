class ValidateAccountIdNotNullConstraintForMachines < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :machines, name: 'machines_account_id_null'

    change_column_null :machines, :account_id, false
    remove_check_constraint :machines, name: 'machines_account_id_null'
  end
end
