class ValidateAccountIdNotNullConstraintForLicenses < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :licenses, name: 'licenses_account_id_null'

    change_column_null :licenses, :account_id, false
    remove_check_constraint :licenses, name: 'licenses_account_id_null'
  end
end
