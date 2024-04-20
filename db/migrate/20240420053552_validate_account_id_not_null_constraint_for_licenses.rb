class ValidateAccountIdNotNullConstraintForLicenses < ActiveRecord::Migration[7.1]
  verbose!

  def up
    validate_check_constraint :licenses, name: 'licenses_account_id_not_null'
  end
end
