class ValidateAccountIdNotNullConstraintForMachines < ActiveRecord::Migration[7.1]
  verbose!

  def up
    validate_check_constraint :machines, name: 'machines_account_id_not_null'
  end
end
